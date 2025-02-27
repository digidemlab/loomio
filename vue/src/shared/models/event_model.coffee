import BaseModel from '@/shared/record_store/base_model'

export default class EventModel extends BaseModel
  @singular: 'event'
  @plural: 'events'
  @indices: ['id', 'actorId', 'discussionId', 'sequenceId', 'position', 'depth', 'parentId']

  @eventTypeMap:
    group: 'groups'
    discussion: 'discussions'
    poll: 'polls'
    outcome: 'outcomes'
    stance: 'stances'
    comment: 'comments'
    comment_vote: 'comments'
    membership: 'memberships'
    membership_request: 'membershipRequests'

  relationships: ->
    @belongsTo 'parent', from: 'events'
    @belongsTo 'actor', from: 'users'
    @belongsTo 'discussion'
    @hasMany  'notifications'

  defaultValues: ->
    pinned: false

  parentOrSelf: ->
    if @parentId
      @parent()
    else
      @

  isNested: -> @depth > 1
  isSurface: -> @depth == 1
  surfaceOrSelf: -> if @isNested() then @parent() else @

  children: ->
    @recordStore.events.find(parentId: @id)

  delete: ->
    @deleted = true

  actorName: ->
    @actor().nameWithTitle(@discussion()) if @actor()

  actorUsername: ->
    @actor().username if @actor()

  model: ->
    @recordStore[@constructor.eventTypeMap[@eventable.type]].find(@eventable.id)

  isUnread: ->
    !@discussion().hasRead(@sequenceId)

  markAsRead: ->
    @discussion().markAsRead(@sequenceId) if @discussion()

  beforeRemove: ->
    _.invokeMap(@notifications(), 'remove')

  removeFromThread: =>
    @remote.patchMember(@id, 'remove_from_thread').then => @remove()

  pin: -> @remote.patchMember(@id, 'pin')
  unpin: -> @remote.patchMember(@id, 'unpin')

  canFork: ->
    @kind == 'new_comment' && @isSurface()

  isForkable: ->
    @discussion() && @discussion().isForking() && @kind == 'new_comment'

  isForking: ->
    _.includes @discussion().forkedEventIds, @id

  toggleFromFork: ->
    if @isForking()
      @discussion().update(forkedEventIds: _.without @discussion().forkedEventIds, @id)
    else
      @discussion().forkedEventIds.push @id
    _.invokeMap @recordStore.events.find(parentId: @id), 'toggleFromFork'

  next: ->
    @recordStore.events.find(parentId: @parentId, position: @position + 1)[0]

  previous: ->
    @recordStore.events.find(parentId: @parentId, position: @position - 1)[0]
