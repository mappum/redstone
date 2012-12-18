EventEmitter = require('events').EventEmitter

class Interface extends EventEmitter
    constructor: (@remote) ->
        @remote._connect @ if @remote? and @remote.listening

    _emit: =>
        EventEmitter::emit.apply @, arguments

    emit: =>
        if @listening
            connection.emit.apply connection, arguments for connection in @connections
        else if @remote?
            @remote._emit.apply @remote, arguments
        @

    listen: =>
        @listening = true
        @connections = []
        @

    _connect: (client) =>
        if not @listening then throw new Error 'Tried to connect to a interface that isn\'t listening'
        connection = new Interface(client)
        @connections.push connection
        @_emit 'connection', connection

    remoteAddress: 'direct'

class WebsocketInterface extends EventEmitter
    constructor: (@remoteAddress) ->
    # TODO: implement

module.exports = Interface
module.exports.direct = Interface
module.exports.websocket = WebsocketInterface