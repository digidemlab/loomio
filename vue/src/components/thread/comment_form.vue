<script lang="coffee">
import Session        from '@/shared/services/session'
import Records        from '@/shared/services/records'
import EventBus       from '@/shared/services/event_bus'
import AbilityService from '@/shared/services/ability_service'

import { submitForm }    from '@/shared/helpers/form'
import { submitOnEnter } from '@/shared/helpers/keyboard'
import { last } from 'lodash'

export default
  props:
    comment: Object
    autoFocus: Boolean

  data: ->
    actor: Session.user()
    shouldReset: false
    canSubmit: true

  computed:
    placeholder: ->
      if @comment.parentId
        @$t('comment_form.in_reply_to', {name: @comment.parent().authorName()})
      else
        @$t('comment_form.aria_label')

  methods:
    handleIsUploading: (val) ->
      @canSubmit = !val

    reset: ->
      @shouldReset = !@shouldReset

    init: ->
      @newComment = @comment.isNew()
      @submit = submitForm @, @comment,
        submitFn: =>
          @comment.save()
        flashSuccess: =>
          EventBus.$emit 'commentSaved'
          if !@newComment
            'comment_form.messages.updated'
          else if @comment.isReply()
            'comment_form.messages.replied'
          else
            'comment_form.messages.created'
        flashOptions:
          name: =>
            @comment.parent().authorName() if @comment.isReply()
        successCallback: (data) =>
          @$emit('comment-submitted')
          @reset()
          @init()

      # submitOnEnter @, element: $element
  mounted: ->
    @init()


</script>

<template lang="pug">
v-layout.comment-form.mx-4
  .thread-item__avatar.mr-3
    user-avatar(:user='actor' :size='40')
  form.thread-item__body(v-on:submit.prevent='submit()' @keyup.ctrl.enter="submit()" @keydown.meta.enter="submit()")
    submit-overlay(:value='comment.processing')
    lmo-textarea(:model='comment' @is-uploading="handleIsUploading" field="body" :placeholder="placeholder" :shouldReset="shouldReset" :autoFocus="autoFocus")
      template(v-slot:actions)
        v-layout
          v-spacer
          v-btn.comment-form__cancel-reply(text v-if="comment.parentId" @click="$emit('cancel-reply')" v-t="'common.action.cancel'")
          space
          v-btn.comment-form__submit-button(:disabled="!canSubmit" color="primary" type='submit' v-t="comment.isNew() ? 'comment_form.submit_button.label' : 'common.action.save' ")
</template>
