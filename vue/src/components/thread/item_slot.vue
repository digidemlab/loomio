<script lang="coffee">
import NewComment from '@/components/thread/item/new_comment.vue'
import PollCreated from '@/components/thread/item/poll_created.vue'
import StanceCreated from '@/components/thread/item/stance_created.vue'
import OutcomeCreated from '@/components/thread/item/outcome_created.vue'
import ThreadActivityMixin from '@/mixins/thread_activity'

export default
  mixins: [ThreadActivityMixin]
  props:
    event: Object
    position: String

  components:
    NewComment: NewComment
    PollCreated: PollCreated
    StanceCreated: StanceCreated
    OutcomeCreated: OutcomeCreated
    ThreadItem: -> import('@/components/thread/item.vue')

  data: ->
    height: 200

  watch:
    event: ->
      if @event
        setTimeout => @height = @$refs.box.clientHeight

</script>
<template lang="pug">
.thread-item-slot(ref="box")
  v-sheet.ma-4.pa-4(v-if="!event" color="grey lighten-3" :height="height")
    .grey--text.text-center.display-1 {{position}}

  component(v-if="event" :is="componentForKind(event.kind)" :event='event')
</template>
