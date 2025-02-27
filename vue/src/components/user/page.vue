<style lang="css">
.user-page { margin-top: 16px; }
.user-page__groups { margin-top: 24px; }
.user-page__groups-title { margin: 0; }
.user-page__group { padding: 0 !important; }

.user-page__contact-user {
  margin: 8px 0;
  width: 100%;
}
</style>

<script lang="coffee">
import Records        from '@/shared/services/records'
import EventBus       from '@/shared/services/event_bus'
import AbilityService from '@/shared/services/ability_service'
import ModalService   from '@/shared/services/modal_service'
import UserModalMixin from '@/mixins/user_modal'

import { applyLoadingFunction } from '@/shared/helpers/apply'

import { isEmpty }     from 'lodash'
import { approximate } from '@/shared/helpers/format_time'

export default
  mixins: [UserModalMixin]

  data: ->
    user: {}
    isMembershipsFetchingDone: false
    groups: []
    canContactUser: false
    loadingGroupsForExecuting: false

  created: ->
    # applyLoadingFunction(@, 'loadGroupsFor')
    @init()
    EventBus.$emit 'currentComponent', {page: 'userPage'}
    Records.users.findOrFetchById(@$route.params.key).then @init, (error) ->
      EventBus.$emit 'pageError', error

  methods:
    approximate: approximate
    init: ->
      if @user = (Records.users.find(@$route.params.key) or Records.users.find(username: @$route.params.key))[0]
        EventBus.$emit 'currentComponent', {title: @user.name, page: 'userPage'}
        @loadGroupsFor(@user)
        @watchRecords
          key: @user.id
          collections: ['groups', 'memberships']
          query: (store) =>
            @groups = @user.formalGroups()
            @canContactUser = AbilityService.canContactUser(@user)

    loadGroupsFor: (user) ->
      @loadingGroupsForExecuting = true
      Records.memberships.fetchByUser(user).then =>
        @loadingGroupsForExecuting = false

  computed:
    isEmptyUser: -> isEmpty @user

</script>

<template lang="pug">
v-container.user-page.max-width-800
  loading(v-if='isEmptyUser')
  .user-page__profile(v-if='!isEmptyUser')
    v-layout.user-page__content
      v-flex.user-page__info
        h1.headline {{user.name}}
        .lmo-hint-text @{{user.username}}
        p {{user.shortBio}}
        div(v-t="{ path: 'user_page.locale_field', args: { value: user.localeName() } }", v-if='user.localeName()')
        div(v-t="{ path: 'user_page.location_field', args: { value: user.location } }", v-if='user.location')
        div(v-t="{ path: 'user_page.online_field', args: { value: approximate(user.lastSeenAt) } }", v-if='user.lastSeenAt')
      v-layout.user-page__avatar(column align-center style="max-width: 200px")
        user-avatar(:user='user', size='featured')
        v-btn.user-page__contact-user(color="accent" outlined v-if='canContactUser' @click='openContactRequestModal(user)' v-t="{ path: 'user_page.contact_user', args: { name: user.firstName() } }")
    .user-page__groups
      h3.lmo-h3.user-page__groups-title(v-t="'common.groups'")
      v-list
        v-list-item.user-page__group.lmo-flex.lmo-flex__center(v-for='group in groups', :key='group.id')
          v-avatar(tile size="64")
            img(:src='group.logoUrl()')
          router-link(:to='urlFor(group)') {{group.fullName}}
      loading(v-if='loadingGroupsForExecuting')
</template>
