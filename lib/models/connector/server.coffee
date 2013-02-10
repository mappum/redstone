Model = require '../model'
_ = require 'underscore'

class Server extends Model
  constructor: (options) ->
    super()
    _.extend @, options
  
  send: =>
    @connection.emit.apply @connection, Array::slice.call(arguments, 0)

  connect: (id, callback) =>
    @connection.request 'init',
      type: 'connector'
      id: id,
      callback

module.exports = Server