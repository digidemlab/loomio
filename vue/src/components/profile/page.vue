<script lang="coffee">
import AppConfig      from '@/shared/services/app_config'
import Session        from '@/shared/services/session'
import Records        from '@/shared/services/records'
import EventBus       from '@/shared/services/event_bus'
import AbilityService from '@/shared/services/ability_service'
import ModalService   from '@/shared/services/modal_service'
import LmoUrlService  from '@/shared/services/lmo_url_service'
import openModal      from '@/shared/helpers/open_modal'
import UserService    from '@/shared/services/user_service'

import { submitForm }   from '@/shared/helpers/form'
import { hardReload }   from '@/shared/helpers/window'

export default
  data: ->
    isDisabled: false
    user: null

  created: ->
    @init()
    EventBus.$emit 'currentComponent', { titleKey: 'profile_page.profile', page: 'profilePage'}
    EventBus.$on 'updateProfile', => @init()
    EventBus.$on 'signedIn', => @init()

  computed:
    showHelpTranslate: -> AppConfig.features.app.help_link
    availableLocales: -> AppConfig.locales
    actions: -> UserService.actions(Session.user(), @)

  methods:
    init: ->
      return unless Session.isSignedIn()
      @originalUser = Session.user()
      @user = @originalUser.clone()
      Session.updateLocale(@user.locale)
      @submit = submitForm @, @user,
        flashSuccess: 'profile_page.messages.updated'
        submitFn: Records.users.updateProfile
        successCallback: @init

    changePicture: ->
      openModal
        component: 'ChangePictureForm'

    changePassword: ->
      @openChangePasswordModal(@user)

    openDeleteUserModal: ->
      @isDeleteUserModalOpen = true

    closeDeleteUserModal: ->
      @isDeleteUserModalOpen = false


</script>
<template lang="pug">
v-container.profile-page.max-width-1024
  loading(v-if='!user')
  div(v-if='user')
    v-card
      submit-overlay(:value='user.processing')
      v-card-title
        h1.headline(v-t="'profile_page.edit_profile'")
      v-card-text
        v-layout
          v-flex.profile-page__details
            v-text-field.profile-page__name-input(:label="$t('profile_page.name_label')" required v-model="user.name")
            validation-errors(:subject='user', field='name')

            v-text-field#user-username-field.profile-page__username-input(:label="$t('profile_page.username_label')" required v-model="user.username")
            validation-errors(:subject='user', field='username')

            v-text-field#user-email-field.profile-page__email-input(:label="$t('profile_page.email_label')" required='ng-required', v-model='user.email')
            validation-errors(:subject='user', field='email')

            lmo-textarea(:model='user' field="shortBio" :label="$t('profile_page.short_bio_label')" :placeholder="$t('profile_page.short_bio_placeholder')")
            validation-errors(:subject='user', field='shortBio')

            v-text-field#user-location-field.profile-page__location-input(v-model='user.location' :label="$t('profile_page.location_label')" :placeholder="$t('profile_page.location_placeholder')")

            v-select#user-locale-field(:label="$t('profile_page.locale_label')" :items="availableLocales" v-model="user.selectedLocale" item-text="name" item-value="key")
            validation-errors(:subject='user', field='selectedLocale')
            p(v-if='showHelpTranslate')
              router-link.md-caption(v-t="'profile_page.help_translate'", to='https://www.loomio.org/g/cpaM3Hsv/loomio-community-translation', target='_blank')
          v-flex.profile-page__avatar.mx-4
            user-avatar(:user='originalUser', size='featured')
            v-btn.profile-page__change-picture(color="accent" @click='changePicture()' v-t="'profile_page.change_picture_link'")
      v-card-actions.profile-page__update-account
        v-spacer
        v-btn.profile-page__update-button(color="primary" @click='submit()' :disabled='isDisabled' v-t="'profile_page.update_profile'")

    v-card.profile-page-card.mt-4
      v-list
        v-list-item(v-for="(action, key) in actions" :key="key" v-if="action.canPerform()" @click="action.perform()")
          v-list-item-icon
            v-icon {{action.icon}}
          v-list-item-title(v-t="action.name")
      //-
      //-   v-btn.profile-page__change-password(color="accent" outlined @click='changePassword()' v-t="'profile_page.change_password_link'")
      //- v-card-text
      //-   h3.lmo-h3(v-t="'profile_page.deactivate_account'")
      //-   v-btn.profile-page__deactivate(outlined color="warning" @click='openConfirmModal(deactivateUserConfirmOpts)', v-t="'profile_page.deactivate_account'")
      //-
      //-   h3.lmo-h3(v-t="'profile_page.delete_account'")
      //-   v-btn.profile-page__delete(outlined color="warning" @click='openConfirmModal(deleteUserConfirmOpts)', v-t="'profile_page.delete_user_link'")

</template>
