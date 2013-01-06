Model = require './model'

class Player extends Model
    constructor: (options) ->
        super()
        options = options or {}
        @[k] = v for k,v of options

        @userId = @username.toLowerCase()

    send: (id, data) =>
        @connector.connection.emit 'data', @connectionId, id, data

    kick: (reason) =>
        @kicked = true
        @send 0xff, reason: reason

module.exports = Player