EventEmitter = require('events').EventEmitter

toArray = (a) -> Array.prototype.slice.call a

class Interface extends EventEmitter
    constructor: (@remote) ->
        if @remote?
            if @remote.listening then @remote._connect @
            else @remote.remote = @

        # the handle or uri others can use to connect to this interface
        @handle = @

    # sends an event to the remote interface
    emit: =>
        # first argument is request id, insert null
        args = toArray arguments
        args.splice 1, 0, null

        if @listening
            connection.emit.apply connection, args for connection in @connections
        else if @remote?
            @remote._emit.apply @remote, args
        @

    # listens for events sent by remote interface
    #on: =>

    # makes a request to the the remote interface, and calls the callback on response
    request: =>
        args = toArray arguments
        callback = args.splice(args.length-1, 1)[0]

        # generate request id and insert as first argument after event name
        id = Math.floor(Math.random() * 0xfffffffff).toString(16)
        args.splice 1, 0, id

        # listen for response
        @once id, callback

        @remote._emit.apply @remote, args
        @

    # listens for requests sent by remote interface
    respond: (event, callback) =>
        @on event, (id) =>
            if id?
                res = =>
                    args = toArray arguments
                    args.splice 0, 0, id
                    @emit.apply @, args

                args = toArray arguments
                args.splice 0, 1, res
                callback.apply @, args

    # tells this interface to listen for remote interface connections
    listen: =>
        @listening = true
        @connections = []
        @

    _emit: (event, id) =>
        # if there is no request id, remove it from arguments
        args = toArray arguments
        if not id? then args.splice 1, 1
        EventEmitter::emit.apply @, args

    _connect: (client) =>
        if not @listening then throw new Error 'Tried to connect to a interface that isn\'t listening'
        connection = new Interface(client)
        @connections.push connection
        @_emit 'connection', connection, null

    remoteAddress: 'direct'
    type: 'direct'

class WebsocketInterface extends EventEmitter
    constructor: (@remoteAddress) ->
    # TODO: implement

module.exports = Interface
module.exports.direct = Interface
module.exports.websocket = WebsocketInterface