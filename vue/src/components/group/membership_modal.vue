<script lang="coffee">
import { submitMembership } from '@/shared/helpers/form'
import MembershipModalMixin from '@/mixins/membership_modal'

export default
  mixins: [MembershipModalMixin]
  props:
    membership: Object
    close: Function
  data: ->
    isDisabled: false
  created: ->
    @submit = submitMembership @, @membership,
      successCallback: =>
        @closeModal()
</script>
<template lang="pug">
v-card.membership-modal
  submit-overlay(:value='membership.processing')
  v-card-title
    h1.headline(v-t="{ path: 'membership_form.modal_title.' + membership.target().constructor.singular, args: { pollType: membership.target().pollType } }")
    v-spacer
    dismiss-modal-button(:close="close")
  v-card-text.membership-form
    p.lmo-hint-text.membership-form__helptext(v-t="{ path: 'membership_form.title_helptext.' + membership.target().constructor.singular, args: { pollType: membership.target().pollType, name: membership.user().name } }")
    label(for='membership-title', v-t="'membership_form.title_label'")
    v-text-field#membership-title.membership-form__title-input.lmo-primary-form-input(:placeholder="$t('membership_form.title_placeholder')" v-model='membership.title', maxlength='255')
    validation-errors(:subject='membership', field='title')
  v-card-actions.membership-form-actions
    v-spacer
    v-btn.membership-form__submit(color="primary" @click='submit()' v-t="'common.action.save'")
</template>
