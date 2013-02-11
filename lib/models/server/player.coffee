Model = require '../model'

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

module.exports = Player