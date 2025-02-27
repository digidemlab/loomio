import Session       from '@/shared/services/session'
import Records       from '@/shared/services/records'
import Flash         from '@/shared/services/flash'
import EventBus       from '@/shared/services/event_bus'
import AbilityService from '@/shared/services/ability_service'
import LmoUrlService  from '@/shared/services/lmo_url_service'
import openModal      from '@/shared/helpers/open_modal'
import ConfirmModalMixin from '@/mixins/confirm_modal'

export default new class ThreadService
  actions: (discussion, vm) ->
    pin_thread:
      icon: 'mdi-pin'
      name: 'action_dock.pin_thread'
      canPerform: -> AbilityService.canPinThread(discussion)
      perform: => @pin(discussion)

    unpin_thread:
      icon: 'mdi-pin-off'
      name: 'action_dock.unpin_thread'
      canPerform: -> AbilityService.canUnpinThread(discussion)
      perform: => @unpin(discussion)

    mute_thread:
      name: 'volume_levels.mute'
      icon: 'mdi-volume-mute'
      canPerform: -> !discussion.isMuted()
      perform: => @mute(discussion)

    unmute_thread:
      name: 'volume_levels.unmute'
      icon: 'mdi-volume-high'
      canPerform: -> discussion.isMuted()
      perform: => @mute(discussion)

    dismiss_thread:
      name: 'dashboard_page.mark_as_read'
      icon: 'mdi-check'
      canPerform: -> discussion.isUnread()
      perform: => @dismiss(discussion)

    announce_thread:
      icon: 'mdi-bullhorn'
      canPerform: -> AbilityService.canEditThread(discussion)
      perform: ->
        openModal
          component: 'AnnouncementForm'
          props:
            announcement: Records.announcements.buildFromModel(discussion)

    react:
      canPerform: -> AbilityService.canAddComment(discussion)

    edit_tags:
      icon: 'mdi-tag'
      name: 'loomio_tags.card_title'
      canPerform: -> AbilityService.canEditThread(discussion)
      perform: ->
        openModal
          component: 'TagsModal',
          props: { discussion: discussion }

    add_comment:
      icon: 'mdi-reply'
      canPerform: -> AbilityService.canAddComment(discussion)
      perform: -> vm.$vuetify.goTo('#add-comment')

    show_history:
      icon: 'mdi-history'
      canPerform: -> discussion.edited()
      perform: ->
        openModal
          component: 'RevisionHistoryModal'
          props:
            model: discussion

    edit_thread:
      icon: 'mdi-pencil'
      canPerform: -> AbilityService.canEditThread(discussion)
      perform: ->
        openModal
          component: 'DiscussionForm',
          props:
            discussion: discussion.clone()

    translate_thread:
      icon: 'mdi-translate'
      menu: true
      canPerform: -> AbilityService.canTranslate(discussion)
      perform: -> discussion.translate(Session.user().locale)

    close_thread:
      menu: true
      perform: => @close(discussion)
      canPerform: -> !discussion.closedAt

    reopen_thread:
      menu: true
      perform: => @reopen(discussion)
      canPerform: -> AbilityService.canReopenThread(discussion)

    move_thread:
      menu: true
      perform: ->
        openModal
          component: 'MoveThreadForm'
          props: { discussion: discussion.clone() }
      canPerform: -> AbilityService.canMoveThread(discussion)

    delete_thread:
      menu: true
      canPerform: -> AbilityService.canDeleteThread(discussion)
      perform: ->
        openModal
          component: 'ConfirmModal',
          props:
            confirm:
              submit: discussion.destroy
              text:
                title: 'delete_thread_form.title'
                helptext: 'delete_thread_form.body'
                submit: 'delete_thread_form.confirm'
                flash: 'delete_thread_form.messages.success'
              redirect: LmoUrlService.group discussion.group()

  mute: (thread, override = false) ->
    if !Session.user().hasExperienced("mutingThread") and !override
      Records.users.saveExperience("mutingThread")
      Records.users.updateProfile(Session.user()).then ->
        ConfirmModalMixin.methods.openConfirmModal(
          submit: -> thread.saveVolume('mute', true)
          text:
            title: 'mute_explanation_modal.mute_thread'
            flash: 'discussion.volume.mute_message'
            fragment: 'mute_thread'
        )
    else
      previousVolume = thread.volume()
      thread.saveVolume('mute').then =>
        Flash.success "discussion.volume.mute_message",
          name: thread.title
        , 'undo', => @unmute(thread, previousVolume)

  unmute: (thread, previousVolume = 'normal') ->
    thread.saveVolume(previousVolume).then =>
      Flash.success "discussion.volume.unmute_message",
        name: thread.title
      , 'undo', => @mute(thread)

  close: (thread) ->
    if !Session.user().hasExperienced("closingThread")
      Records.users.saveExperience("closingThread")
      Records.users.updateProfile(Session.user()).then ->
        ConfirmModalMixin.methods.openConfirmModal(
          submit: thread.close
          text:
            title: 'close_explanation_modal.close_thread'
            fragment: 'close_thread'
            flash: 'discussion.closed.closed'
        )
    else
      thread.close().then =>
        Flash.success "discussion.closed.closed", {}, 'undo', => @reopen(thread)

  reopen: (thread) ->
    thread.reopen().then =>
      Flash.success "discussion.closed.reopened", {}, 'undo', => @close(thread)

  dismiss: (thread) ->
    if !Session.user().hasExperienced("dismissThread")
      Records.users.saveExperience("dismissThread")
      ConfirmModalMixin.methods.openConfirmModal(
        submit: => @dismiss(thread)
        text:
          title: 'dismiss_explanation_modal.dismiss_thread'
          helptext: 'dismiss_explanation_modal.body_html'
          submit: 'dismiss_explanation_modal.dismiss_thread'
          flash: 'dashboard_page.thread_dismissed'
      )
    else
      thread.dismiss().then =>
        Flash.success "dashboard_page.thread_dismissed", {}, 'undo', => @recall(thread)

  recall: (thread) ->
    thread.recall().then =>
      Flash.success "dashboard_page.thread_recalled", {}, 'undo', => @dismiss(thread)

  pin: (thread) ->
    if !Session.user().hasExperienced("pinningThread")
      Records.users.saveExperience("pinningThread").then ->
        ConfirmModalMixin.methods.openConfirmModal(
          submit: thread.savePin
          text:
            title: 'pin_thread_modal.title'
            flash: 'discussion.pin.pinned'
            fragment: 'pin_thread'
        )
    else
      thread.savePin().then =>
        Flash.success "discussion.pin.pinned", 'undo', => @unpin(thread)

  unpin: (thread) ->
    thread.savePin().then =>
      Flash.success "discussion.pin.unpinned", 'undo', => @pin(thread)
