import Session       from '@/shared/services/session'
import Records       from '@/shared/services/records'
import Flash         from '@/shared/services/flash'
import EventBus       from '@/shared/services/event_bus'
import AbilityService from '@/shared/services/ability_service'
import LmoUrlService  from '@/shared/services/lmo_url_service'
import openModal      from '@/shared/helpers/open_modal'

export default new class PollService
  actions: (poll, vm) ->
    announce_poll:
      icon: 'mdi-bullhorn'
      canPerform: ->
        AbilityService.canEditPoll(poll)
      perform: ->
        openModal
          component: 'AnnouncementForm'
          props:
            announcement: Records.announcements.buildFromModel(poll)

    edit_poll:
      name: 'common.action.edit'
      canPerform: ->
        AbilityService.canEditPoll(poll)
      perform: ->
        openModal
          component: 'PollCommonModal'
          props:
            poll: poll.clone()

    show_history:
      icon: 'mdi-history'
      canPerform: -> poll.edited()
      perform: ->
        openModal
          component: 'RevisionHistoryModal'
          props:
            model: poll

    translate_poll:
      icon: 'mdi-translate'
      menu: true
      canPerform: -> AbilityService.canTranslate(poll)
      perform: -> poll.translate(Session.user().locale)

    close_poll:
      name:
        path: 'poll_common.close_poll_type'
        args: {'poll-type': vm.$t(poll.pollTypeKey())}
      canPerform: ->
        AbilityService.canClosePoll(poll)
      perform: ->
        openModal
          component: 'ConfirmModal',
          props:
            confirm:
              submit: -> poll.close()
              successCallback: ->
                openModal
                  component: 'PollCommonOutcomeModal'
                  props:
                    outcome: Records.outcomes.build(pollId: poll.id)
              text:
                title: 'poll_common_close_form.title'
                helptext: 'poll_common_close_form.helptext'
                confirm: 'poll_common_close_form.close_poll'
                flash: 'poll_common_close_form.poll_closed'

    reopen_poll:
      name: 'common.action.reopen'
      canPerform: ->
        AbilityService.canReopenPoll(poll)
      perform: ->
        openModal
          component: 'PollCommonReopenModal'
          props: { poll: poll }

    export_poll:
      name: 'common.action.export'
      canPerform: ->
        AbilityService.canExportPoll(poll)
      perform: ->
        vm.$router.push LmoUrlService.poll(poll, {}, action: 'export', absolute: true)

    delete_poll:
      name: 'common.action.delete'
      canPerform: ->
        AbilityService.canDeletePoll(poll)
      perform: ->
        openModal
          component: 'ConfirmModal'
          props:
            confirm:
              submit: -> poll.destroy()
              text:
                title: 'poll_common_delete_modal.title'
                confirm: 'poll_common_delete_modal.question'
                flash: 'poll_common_delete_modal.success'
