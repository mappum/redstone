Model = require '../model'
_ = require 'underscore'

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
      @sendServer 'data', packet.id, packet

    @server.connection.emit 'join', @toJson(), {}

  send: (id, data) =>
    @connection.write id, data

  sendServer: =>
    args = Array::slice.call arguments, 0
    args.splice 1, 0, @id
    @server.send.apply @server, args

  toJson: =>
    _.omit @, 'server', 'connection'

module.exports = Client