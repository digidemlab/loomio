<script lang="coffee">
import AppConfig      from '@/shared/services/app_config'
import Session        from '@/shared/services/session'
import Records        from '@/shared/services/records'
import EventBus       from '@/shared/services/event_bus'
import AbilityService from '@/shared/services/ability_service'
import RecordLoader   from '@/shared/services/record_loader'
import ModalService   from '@/shared/services/modal_service'
import LmoUrlService  from '@/shared/services/lmo_url_service'

import { applyLoadingFunction } from '@/shared/helpers/apply'
import Loading from '@/components/common/loading.vue'
import PollCommonPreview from '@/components/poll/common/preview.vue'

import _map from 'lodash/map'
import _capitalize from 'lodash/capitalize'
import _sortBy from 'lodash/sortBy'
import _isEmpty from 'lodash/isEmpty'
import _filter from 'lodash/filter'

export default
  components:
    Loading: Loading
    PollCommonPreview: PollCommonPreview
  data: ->
    group: {}
    now: moment()
    pollIds: []
    loader: new RecordLoader
      collection: 'polls'
      path: 'search'
      params: @$route.params
      per: 25
    fragment: null
    pollsCount: null
    fetchRecordsExecuting: false
    loadMoreExecuting: false
    statusFilter: null
    groupFilter: null

  created: ->
    EventBus.$emit 'currentComponent', {
      group: poll.group(),
      titleKey: 'polls_page.heading',
      page: 'pollsPage'}
    # applyLoadingFunction @, 'loadMore'
    # applyLoadingFunction @, 'fetchRecords'
    # applyLoadingFunction(@, 'searchPolls')
    @init()
    EventBus.$on 'signedIn', => @init()
  computed:
    statusFilters: -> _map AppConfig.searchFilters.status, (filter) =>
      { name: _capitalize(filter), value: filter }

    groupFilters: -> _map Session.user().groups(), (group) =>
      { name: group.fullName, value: group.key }

    loadedCount: ->
      @pollCollection().polls().length

    canLoadMore: ->
      !@fragment && @loadedCount < @pollsCount

    fetching: ->
      @fetchRecordsExecuting || @loadMoreExecuting

    orderedPolls: ->
      _sortBy(@pollCollection().polls(), 'pollImportance')

    hasGroup: ->
      !_isEmpty(@group)

  methods:
    pollImportance: (poll) -> poll.importance(@now)
    loadMore: ->
      @loadMoreExecuting = true
      @loader.loadMore().then (response) =>
        @loadMoreExecuting = false
        @pollIds = @pollIds.concat _map(response.polls, 'id')
    init: ->
      @statusFilter = @$route.query.status
      @groupFilter = @$route.query.group_key
      @pollIds = []

      Records.polls.searchResultsCount(@$route.query).then (response) =>
        @pollsCount = response.count

      @fetchRecordsExecuting = true
      @loader.fetchRecords().then (response) =>
        @fetchRecordsExecuting = false
        @group   = Records.groups.find(@$route.query.group_key)
        @pollIds = _map(response.polls, 'id')
      , (error) ->
        @fetchRecordsExecuting = false
        EventBus.$emit 'pageError', error
    startNewPoll: ->
      ModalService.open 'PollCommonStartModal', poll: -> Records.polls.build(authorId: Session.user().id)

    searchPolls: =>
      if @fragment
        Records.polls.search(query: @fragment, per: 10)
      else
        Promise.resolve(true)

    pollCollection: ->
      polls: =>
        _sortBy(
          _filter(Records.polls.find(@pollIds), (poll) =>
            _isEmpty(@fragment) or poll.title.match(///#{@fragment}///i)), '-createdAt')
  watch:
    statusFilter: (v) ->
      @$router.push({ path: '/polls', query: { status: v, group_key: @groupFilter } })
      @init()
    groupFilter: (v) ->
      @$router.push({ path: '/polls', query: { group_key: v, status: @statusFilter } })
      @init()


</script>
<template lang="pug">
v-container.lmo-main-container.polls-page
  h1.lmo-h1.dashboard-page__heading.polls-page__heading(v-if='hasGroup')
    router-link(:to='urlFor(group)')
      span(v-t="{ path: 'polls_page.heading_with_group', args: { name: group.fullName }}")
  h1.lmo-h1.dashboard-page__heading.polls-page__heading(v-if='!hasGroup', v-t="'polls_page.heading'")
  v-card.lmo-main-container.polls-page
    v-card-text
      .polls-page__filters
        v-select.polls-page__status-filter(v-model="statusFilter" :placeholder="$t('polls_page.filter_placeholder')" :items="statusFilters" item-value="value" item-text="name")
        v-select.polls-page__group-filter(v-model="groupFilter" :placeholder="$t('polls_page.groups_placeholder')" :items="groupFilters" item-value="value" item-text="name")
      //
        <div class="polls-page__filters lmo-flex">
        <md-input-container md-no-float="true" class="polls-page__search md-block"><i class="mdi mdi-magnify mdi-18px"></i>
        <input ng-model="fragment" placeholder="{{\'polls_page.search_placeholder\' | translate}}" ng-change="searchPolls()" ng-model-options="{debounce: 250}">
        </md-input-container>
        <md-select ng-model="statusFilter" placeholder="{{ \'polls_page.filter_placeholder\' | translate }}" ng-change="fetchRecords()" class="polls-page__status-filter">
        <md-option ng-value="null">{{ 'polls_page.filter_placeholder' | translate }}</md-option>
        <md-option ng-repeat="filter in statusFilters track by filter.value" ng-value="filter.value">{{filter.name}}</md-option>
        </md-select>
        <md-select ng-model="groupFilter" placeholder="{{ \'polls_page.groups_placeholder\' | translate }}" ng-change="fetchRecords()" class="polls-page__group-filter">
        <md-option ng-value="null">{{ 'polls_page.groups_placeholder' | translate }}</md-option>
        <md-option ng-repeat="filter in groupFilters track by filter.value" ng-value="filter.value">{{filter.name}}</md-option>
        </md-select>
        </div>
      loading(v-if='fetchRecordsExecuting')
      v-list.polls-page__polls(v-if='!fetchRecordsExecuting' two-line)
        v-list-item(v-for='poll in orderedPolls', :key='poll.id')
          v-list-item-content
            poll-common-preview(:key='poll.id', :poll='poll', :display-group-name='!group')
      loading(v-if='loadMoreExecuting')
      .polls-page__count(v-t="{ path: 'polls_page.polls_count', args: { count: loadedCount, total: pollsCount }}")
      .polls-page__load-more(v-if='canLoadMore')
        v-btn.md-primary(md-button='', v-t="'poll_common.load_more'", @click='loadMore()')
</template>
<style lang="css">
.polls-page {
  margin-top: 16px;
}

.polls-page__heading a {
  /* // color: $primary-text-color; */
}

.polls-page__filters {
  align-items: center;
}

/* // .polls-page__status-filter {
//   margin-left: 30px;
//   margin-right: 30px;
// }
//
// .polls-page__group-filter {
//   min-width: 200px;
// } */

.polls-page__icon {
  vertical-align: middle;
  margin-bottom: 4px;
}

.polls-page__count {
  font-weight: bold;
  margin-top: 16px;
}

.polls-page__load-more {
  margin-bottom: 16px;
}

.polls-page__search {
  flex-grow: 1;
  margin: 16px 0 -10px;
  i {
    position: absolute;
    right: 0;
    /* // color: $grey-on-white; */
  }
}

/* // @media (max-width: $small-max-px) {
//   .polls-page__filters { flex-direction: column; }
//   .polls-page__search { width: 100%; }
//   .polls-page__status-filter,
//   .polls-page__group-filter {
//     width: 100%;
//   }
// } */
</style>
