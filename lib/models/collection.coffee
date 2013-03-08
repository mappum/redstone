Model = require './model'

get = (model, key, assert = true) ->
  key += ''
  keys = key.split '.'
  cursor = model

  for k, i in keys
    getKey = ->  key = ''; key += keys[j] for j in [0..i]; key
    cursor = cursor[k]

    if i < keys.length - 1
      if not cursor?
        if assert then throw new Error "Model has no value at key '#{getKey()}'"
        else return

      if typeof cursor != 'object'
        if assert then throw new Error "Key #{getKey()} is not an object"
        else return

  cursor + ''

remove = (array, model) ->
  i = array.indexOf model
  array.splice i, 1 if i != -1

# index options:
#   sparse - only indexed if model has that value
#   duplicate - multiple models can be indexed by the same value (can't be used w/ override or replace)
#   override - overrides models indexed by the same value (can't be used w/ duplicate or replace)
#   replace - like override, but deletes old values (can't be used w/ override or duplicate)

# TODO: make option to listen for changes to indexed values, and/or regenerate indexes

class Collection extends Model
  constructor: (models, options) ->
    super()

    if not options? and not (models instanceof Array)
      options = models
      models = null

    models = models or []

    indexes = if options?.indexes? then options.indexes else []
    @_indexes = {}
    @createIndex index for index in indexes
    @createIndex 'id' if not @_indexes.id?

    @__defineGetter__ 'length', => @models.length

    @models = []
    @insert model for model in models

  insert: (model) ->
    model.id = @generateId model if not model.id?
    @setIndex index, model for index of @_indexes
    @models.push model
    @emit 'insert', model

  get: (index, key) ->
    # if only one argument and it is a number, return models[key]
    # if it is not a number, default to 'id' index
    if not key?
      if typeof index == 'number' then return @models[index]
      else
        key = index
        index = 'id'

    @getIndex index, key

  remove: (index, key) ->
    # if index is an object, use it as the model
    if typeof index == 'object'
      return @removeModel index

    # if index is a number, use it as a numerical index (models[index])
    else if typeof index == 'number'
      return @removeModel @models[index]

    # otherwise, remove all models indexed at index[key] (index defaults to id)
    else
      if not key?
        key = index
        index = 'id'

      models = @getIndex index, key
      index = @_indexes[index]

      if index.duplicate
        # delete the whole value array so we don't have to keep searching through it
        delete index.models[key]
        @removeModel model for model in models
      else
        @removeModel models

      models

  removeModel: (model) ->
    remove @models, model

    for key, index of @_indexes
      value = get model, key, not index.sparse

      if index.duplicate
        arr = index.models[value]
        remove arr, model if arr?

      else delete index.models[value]

    @emit 'remove', model

  createIndex: (index) ->
    if typeof index == 'string' then index = {key: index}
    else if typeof index == 'object'
      throw new Error 'No key specified for index' if not index.key?
    throw new Error "Tried to create duplicate index '#{index.key}'" if @_indexes[index.key]?
    if +(index.duplicate or false) + +(index.override or false) + +(index.replace or false) > 1
      throw new Error "Cannot use 'duplicate', 'override', or 'replace' together"

    index.models = {}
    @_indexes[index.key] = index

  setIndex: (key, model) ->
    index = @_indexes[key]
    value = get model, index.key, not index.sparse

    if not value? or value == null
      throw new Error 'Model has no value at indexed key #{key}' if not index.sparse
      return

    if index.duplicate
      arr = index.models[value]
      arr = index.models[value] = [] if not arr?
      arr.push model if arr.indexOf(model) == -1
    else
      if index.models[value]?
        if index.replace
          @removeModel index.models[value]
        else if not index.override
          throw new Error "Duplicate indexed value (#{key} -> #{value})"
      index.models[value] = model

  getIndex: (index, key) ->
    index = @_indexes[index]
    throw new Error "Tried to lookup on nonexistent index '#{index}'" if not index?
    value = index.models[key]
    return [] if not value? and index.duplicate
    value

  generateId: (model) ->
    return model.id if model.id?
    while not id? or @_indexes.id.models[id]?
      id = Math.floor(Math.random() * 2821109907455).toString(36)
    id

module.exports = Collection