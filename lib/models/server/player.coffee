Model = require '../model'
_ = require 'underscore'

class Player extends Model
    constructor: (options) ->
        super()
        options = options or {}
        @[k] = v for k,v of options

        @userId = @username.toLowerCase()

    _send: (event) =>
        args = [event, @id]
        args = args.concat Array::slice.call(arguments, 1)
        @connector.connection.emit.apply @connector.connection, args

    send: (id, data) =>
        @_send 'data', id, data

    kick: (reason) =>
        @kicked = true
        @send 0xff, reason: reason

    ping: (cb) ->
        id = Math.floor Math.random() * 0xffffffff / 2
        start = Date.now()
        onPong = (e, packet) ->
            if packet.keepAliveId == id
                @off 0x0, onPong
                cb Date.now() - start
        @on 0x0, onPong
        @send 0x0, keepAliveId: id

    toJson: ->
        json = _.omit @, 'connector', 'stacks', _.functions(@)
        @emit 'toJson', json
        json

module.exports = Player