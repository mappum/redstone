Model = require '../model'
Collection = require '../collection'
_ = require 'underscore'

class Region extends Model
  constructor: (options) ->
    _.extend @, options
    @servers = new Collection
    @map = {}

module.exports = Region