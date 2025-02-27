<script lang="coffee">
import EventBus from '@/shared/services/event_bus'
import WatchRecords from '@/mixins/watch_records'
import Records from '@/shared/services/records'

import { submitOnEnter } from '@/shared/helpers/keyboard'
import { submitStance }  from '@/shared/helpers/form'

import {compact, map, toPairs, fromPairs, some, sortBy} from 'lodash'

export default
  mixins: [WatchRecords]
  props:
    stance: Object
  data: ->
    stanceChoices: []
    pollOptions: []
    zone: null
    canRespondMaybe: null
    stanceValues: []

  created: ->
    EventBus.$on 'timeZoneSelected', (e, zone) => @zone = zone

    @watchRecords
      collections: ['poll_options', 'poll']
      query: (records) =>
        @canRespondMaybe =  @stance.poll().customFields.can_respond_maybe
        @stanceValues = if @stance.poll().customFields.can_respond_maybe then [2,1,0] else [2, 0]
        @pollOptions = sortBy @stance.poll().pollOptions(), 'name'

        @stanceChoices = @pollOptions.map (option) =>
          lastChoice = @stance.stanceChoices().find((sc) => sc.pollOptionId == option.id) || {score: 0}
          id: option.id
          pollOption: => option
          poll: => @stance.poll()
          score: lastChoice.score

    @submit = submitStance @, @stance,
      prepareFn: =>
        @$emit 'processing'
        @stance.id = null
        attrs = compact @stanceChoices.map (choice) ->
          {poll_option_id: choice.id, score: choice.score} if choice.score > 0

        if some(attrs)
          @stance.stanceChoicesAttributes = attrs

  methods:
    buttonStyleFor: (choice, score) ->
      if choice.score == score
        {opacity: 1}
      else
        {opacity: 0.3}

    imgForScore: (score) ->
      name = switch score
        when 2 then 'agree'
        when 1 then 'abstain'
        when 0 then 'disagree'
      "/img/#{name}.svg"

    incrementScore: (choice) ->
      if @canRespondMaybe
        choice.score = (choice.score + 5) % 3
      else
        choice.score = if choice.score == 2
          0
        else
          2


</script>

<template lang='pug'>
form.poll-meeting-vote-form(@submit.prevent='submit()')
  h3.lmo-card-subheading.lmo-flex__grow(v-t="'poll_meeting_vote_form.your_response'")
  .poll-common-vote-form__options
    //- h3.lmo-h3.poll-meeting-vote-form--box(v-t="'poll_meeting_vote_form.can_attend'")
    //- h3.lmo-h3.poll-meeting-vote-form--box(v-t="'poll_meeting_vote_form.if_need_be'", v-if='canRespondMaybe')
    //- h3.lmo-h3.poll-meeting-vote-form--box(v-t="'poll_meeting_vote_form.unable'")
    //- time-zone-select.lmo-margin-left
    v-layout.poll-common-vote-form__option(wrap v-for='choice in stanceChoices' :key='choice.id')
      poll-common-stance-choice(:stance-choice='choice' :zone='zone' @click="incrementScore(choice)")
      v-spacer
      v-btn.poll-meeting-vote-form--box(icon :style="buttonStyleFor(choice, i)" v-for='i in stanceValues', :key='i', @click='choice.score = i')
        v-avatar(:size="36")
          img.poll-common-form__icon(:src="imgForScore(i)")
  validation-errors(:subject='stance', field='stanceChoices')
  poll-common-add-option-button(:poll='stance.poll()')
  poll-common-stance-reason(:stance='stance')
  .poll-common-form-actions.lmo-flex.lmo-flex__space-between
    poll-common-show-results-button(v-if='stance.isNew()')
    div(v-if='!stance.isNew()')
    v-btn.md-primary.md-raised.poll-common-vote-form__submit(type='submit', v-t="'poll_common.vote'", aria-label=" $t('poll_meeting_vote_form.vote')")
</template>
