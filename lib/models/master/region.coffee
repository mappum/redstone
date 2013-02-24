Model = require '../model'
_ = require 'underscore'

class Region extends Model
  constructor: (options) ->
    _.extend @, options

module.exports = Region