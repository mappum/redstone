Model = require './model'

class Collection extends Model
  constructor: (models, options) ->
    super()
    
    models = models or []

    indexes = if options?.indexes then options.indexes else []
    indexes.push 'id' if indexes.indexOf('id') == -1

    @models = []
    @_indexes = {}
    @_indexes[index] = {} for index in indexes

    @__defineGetter__ 'length', => @models.length

    @insert model for model in models

  insert: (model) ->
    model.id = @generateId model if not model.id?
    @setIndex key, model for key of @_indexes
    @models.push model
    @emit 'insert', model

  get: (key, value) ->
    if not value?
      value = key
      key = if typeof value == 'number' then null else 'id'

    if key?
      return @_indexes[key][value]
    else
      return @models[value]

  remove: (key, value) ->
    model = if typeof key == 'object' then key else @get key, value
    return if not model?

    index = @models.indexOf(model)
    @models.splice index, 1 if index != -1
    for key of @_indexes
      delete @_indexes[key][model[key]]

    @emit 'remove', model if model?

    model

  setIndex: (key, model) ->
    key += ''
    keys = key.split '.'
    cursor = model

    for k, i in keys
      getKey = ->  key = ''; key += keys[j] for j in [0..i]; key
      cursor = cursor[k]
      throw new Error "Model had no value at indexed key '#{getKey()}'" if not cursor?
      throw new Error "Indexed key #{getKey()} is not an object" if i < keys.length-1 and typeof cursor != 'object'
    value = cursor + ''

    # TODO: allow overriding duplicates
    if @_indexes[key][value]?
      throw new Error "Duplicate indexed value (#{key} -> #{value})"

    @_indexes[key][value] = model

  generateId: (model) ->
    return model.id if model.id?
    while not id? or @_indexes.id[id]?
      id = Math.floor(Math.random() * 2821109907455).toString(36)
    id

module.exports = Collection