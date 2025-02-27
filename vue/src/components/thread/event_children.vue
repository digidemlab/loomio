<script lang="coffee">
import AppConfig         from '@/shared/services/app_config'
import EventBus          from '@/shared/services/event_bus'
import NestedEventWindow from '@/shared/services/nested_event_window'
import WatchRecords from '@/mixins/watch_records'
import RecordLoader from '@/shared/services/record_loader'

import NewComment from '@/components/thread/item/new_comment.vue'
import PollCreated from '@/components/thread/item/poll_created.vue'
import StanceCreated from '@/components/thread/item/stance_created.vue'
import OutcomeCreated from '@/components/thread/item/outcome_created.vue'

import ThreadActivityMixin from '@/mixins/thread_activity'

export default
  mixins: [WatchRecords, ThreadActivityMixin]

  components:
    NewComment: NewComment
    PollCreated: PollCreated
    StanceCreated: StanceCreated
    OutcomeCreated: OutcomeCreated
    ThreadItem: -> import('@/components/thread/item.vue')

  props:
    parentEvent: Object

  data: ->
    eventWindow: null
    events: []
    loader: null

  created: ->
    @eventWindow = new NestedEventWindow
      parentEvent: @parentEvent
      discussion:  @parentEvent.discussionId
      per:         10

    @loader = new RecordLoader
      collection: 'events'
      params:
        discussion_id: @parentEvent.discussionId
        parent_id: @parentEvent.id
        order: 'position'
        per: 10

    @watchRecords
      collections: ['events']
      query: (store) =>
        @events = @eventWindow.windowedEvents()

  methods:
    loadPrevious: ->
      @eventWindow.decreaseMin()
      @loader.loadPrevious(@eventWindow.min)

    loadNext: ->
      @eventWindow.increaseMax()
      @loader.loadMore(@eventWindow.lastLoaded()+1) if @eventWindow.canLoadNext()

    debug: -> AppConfig.debug

</script>

<template lang="pug">
.event-children
  //- div(v-if='debug()')
  //-   | event-childrenparentId: {{eventWindow.parentEvent.id}}cc: {{eventWindow.parentEvent.childCount}}min: {{eventWindow.min}}max: {{eventWindow.max}}first: {{eventWindow.firstLoaded()}}last: {{eventWindow.lastLoaded()}}anyPrevious: {{eventWindow.anyPrevious()}}anyNext: {{eventWindow.anyNext()}}

  v-btn.activity-panel__load-more.lmo-no-print(block tile outlined color="accent" v-if='eventWindow.anyPrevious() && !loader.loadingPrevious', @click='loadPrevious()')
    v-icon mdi-autorenew
    span(v-t="{ path: 'activity_card.n_previous', args: { count: eventWindow.numPrevious() } }")
  loading.activity-panel__loading.page-loading(v-show='loader.loadingPrevious')
  component(:is="componentForKind(event.kind)" v-for='event in events' :key='event.id' :event-window='eventWindow' :event='event')
  .activity-panel__load-more.lmo-no-print
    v-btn(block tile outlined color="accent" v-if='eventWindow.anyNext() && !loader.loadingMore', @click='loadNext()')
      v-icon mdi-autorenew
      span(v-t="{ path: 'activity_card.n_more', args: { count: eventWindow.numNext() } }")
  loading.activity-panel__loading.page-loading(v-show='loader.loadingMore')
</template>
<style lang="sass">
.activity-panel__load-more
  margin: 0px 16px 0px 80px

</style>
