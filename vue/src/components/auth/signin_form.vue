<script lang="coffee">
import AuthService  from '@/shared/services/auth_service'
import { hardReload } from '@/shared/helpers/window'
import Session from '@/shared/services/session'
import AuthModalMixin from '@/mixins/auth_modal'
import Flash from '@/shared/services/flash'
import EventBus from '@/shared/services/event_bus'

export default
  mixins: [AuthModalMixin]
  props:
    user: Object
  data: ->
    vars: {}
  methods:
    signIn: ->
      # EventBus.emit $scope, 'processing'
      @user.name = @vars.name if @vars.name?
      onSuccess = (data) =>
        Session.apply(data)
        @closeModal()
        EventBus.$emit('signedIn')
        Flash.success('auth_form.signed_in')
      finished = ->
        console.log 'doneProcessing'
        # EventBus.emit $scope, 'doneProcessing';
        # $scope.$apply();
      AuthService.signIn(@user, onSuccess, finished).finally finished

    signInAndSetPassword: ->
      LmoUrlService.params('set_password', true)
      @signIn()

    sendLoginLink: ->
      # EventBus.emit $scope, 'processing'
      AuthService.sendLoginLink(@user).finally ->
        # EventBus.emit $scope, 'doneProcessing'
        console.log 'doneProcessing'

    submit: ->
      if @user.hasPassword or @user.hasToken
        @signIn()
      else
        @sendLoginLink()
</script>
<template lang="pug">
.auth-signin-form(@keyup.ctrl.enter="submit()" @keydown.meta.enter="submit()" @keydown.enter="submit()")
  v-layout(justify-center)
    auth-avatar(:user='user')
  .auth-signin-form__magic-link
    h2.title.text-center(v-t="{ path: 'auth_form.welcome_back', args: { name: user.firstName() } }")
  .auth-signin-form__token.align-center(v-if='user.hasToken')
    validation-errors(:subject='user', field='token')
    v-btn.auth-signin-form__submit(color="primary" @click='submit()' v-if='!user.errors.token')
      span(v-t="{ path: 'auth_form.sign_in_as', args: {name: user.name}}")
    v-btn.auth-signin-form__submit(color="primary" @click='sendLoginLink()' v-if='user.errors.token')
      span(v-t="'auth_form.login_link'")
    p
      span(v-t="'auth_form.set_password_helptext'")
      a.lmo-pointer(@click='signInAndSetPassword()' v-t="'auth_form.set_password'")
  .auth-signin-form__no-token(v-if='!user.hasToken')
    p.text-center
      span(v-t="'auth_form.login_link_helptext'" v-if='!user.hasPassword')
      span(v-t="'auth_form.login_link_helptext_with_password'" v-if='user.hasPassword')

    .auth-signin-form__password(v-if='user.hasPassword')
      label(v-t="'auth_form.password'")
      v-text-field#password.lmo-primary-form-input(name='password' password autofocus required v-model='user.password')
      validation-errors(:subject='user', field='password')

      v-card-actions
        v-btn.auth-signin-form__login-link(:color="!user.hasPassword ? 'primary' : 'accent'" v-t="'auth_form.login_link'" @click='sendLoginLink()')
        v-btn.auth-signin-form__submit(v-t="'auth_form.sign_in'" @click='submit()' :disabled='!user.password' v-if='user.hasPassword')

    .auth-signin-form__no-password(v-if='!user.hasPassword')
      v-layout(justify-center)
        v-btn.auth-signin-form__submit(color="primary" @click='sendLoginLink()' v-t="'auth_form.login_link'")
</template>

<style lang="sass">
.auth-signin-form__no-password .auth-signin-form__submit
  display: block

</style>
