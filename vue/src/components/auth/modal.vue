<script lang="coffee">
import AppConfig from '@/shared/services/app_config'
import Records       from '@/shared/services/records'
import EventBus      from '@/shared/services/event_bus'
import AuthService from '@/shared/services/auth_service'

export default
  props:
    preventClose: Boolean
    close: Function

  data: ->
    siteName: AppConfig.theme.site_name
    user: Records.users.build()
    isDisabled: false

  mounted: ->
    AuthService.applyEmailStatus(@user, AppConfig.pendingIdentity)

  methods:
    back: -> @user.emailStatus = null

  computed:
    showBackButton: ->
      @user.emailStatus and
      !@user.sentLoginLink and
      !@user.sentPasswordLink
</script>
<template lang="pug">
v-card.auth-modal
  submit-overlay(:value='isDisabled')
  v-card-title
    //- i.mdi.mdi-lock-open(ng-if='!showBackButton()')
    //- a.auth-modal__back(ng-click='back()', ng-if='showBackButton()')
    //-   i.mdi.mdi-keyboard-backspace
    h1.headline(v-t="{ path: 'auth_form.sign_in_to_loomio', args: { site_name: siteName } }")
    v-spacer
    dismiss-modal-button(v-if='!preventClose' :close="close")
  v-card-text
    auth-form(:user='user')
</template>
