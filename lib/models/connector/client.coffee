Model = require '../model'
_ = require 'underscore'

ignore = {0xa: 1}

class Client extends Model
  constructor: (options) ->
    super()
    _.extend @, options

  start: =>
    @connection.on 'end', =>
      @sendServer 'quit'
      @emit 'quit'

    # when we recieve data from the client, send it to the server
    @connection.on 'packet', (packet) =>
      @sendServer 'data', packet.id, packet if not ignore[packet.id]

    @server.connection.emit 'join', @toJson(), {}

  send: (id, data) =>
    if id == 0xff then @connection.end data.reason
    else @connection.write id, data

  kick: (reason) =>
    @connection.end reason

  sendServer: =>
    args = Array::slice.call arguments, 0
    args.splice 1, 0, @id
    @server.connection.emit.apply @server.connection, args

  toJson: =>
    _.omit @, 'server', 'connection', 'stacks', _.functions(@)

module.exports = Client