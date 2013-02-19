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
    if model[key]?
      if @_indexes[key][model[key]]?
        throw new Error("Duplicate indexed value (#{key} -> #{model[key]})")
      @_indexes[key][model[key]] = model

  generateId: (model) ->
    return model.id if model.id?
    while not id? or @_indexes.id[id]?
      id = Math.floor(Math.random() * 2821109907455).toString(36)
    id

module.exports = Collection