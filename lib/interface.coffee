EventEmitter = require('events').EventEmitter
io = require 'socket.io'
ioc = require 'socket.io-client'

toArray = (a) -> Array.prototype.slice.call a
removeId = (listener) -> => listener.apply @, toArray(arguments).slice 1

class Interface extends EventEmitter
    constructor: (remote) ->
        @_connect remote if remote?

    # sends an event to the remote interface
    emit: (event) =>
        if event != 'newListener'
            # first argument is request id, insert null
            args = toArray arguments
            args.splice 1, 0, null
            @_send.apply @, args
            @

    # listens for events sent by remote interface
    on: (event, listener) =>
        if event == 'connection' and @listening then EventEmitter::on.call @, event, listener
        else @_on event, removeId listener

    # listens for events sent by remote interface, then removes listener
    once: (event, listener) =>
        if event == 'connection' and @listening then EventEmitter::once.call @, event, listener
        else @_once event, removeId listener

    # makes a request to the the remote interface, and calls the listener on response
    request: =>
        args = toArray arguments
        listener = args.splice(args.length-1, 1)[0]

        # generate request id and insert as first argument after event name
        id = Math.floor(Math.random() * 0xfffffffff).toString(36)
        args.splice 1, 0, id

        # listen for response
        @_on id, listener

        # send request data
        @_send.apply @, args
        @

    # listens for requests sent by remote interface
    respond: (event, listener) =>
        @_on event, (id) =>
            if id?
                # makes function for responding to request
                res = =>
                    args = toArray arguments
                    args.splice 0, 0, id
                    @_send.apply @, args

                # insert response function and call listener
                args = toArray arguments
                args.splice 0, 1, res
                listener.apply @, args

    # tells this interface to listen for remote interface connections
    listen: =>
        @listening = true
        @_listen.apply @, toArray arguments
        @

    # setup for listening
    _listen: =>
        @connections = []

    # registers an event listener
    _on: (event, listener) => EventEmitter::on.call @, event, listener

    # registers an event listener, then removes listener
    _once: (event, listener) => EventEmitter::once.call @, event, listener

    # does the actual sending to the remote interface
    _send: => @remote._emit.apply @remote, toArray arguments

    # connects to remote
    _connect: (@remote) =>
        if @remote.listening
            connection = new Interface @
            @remote.connections.push connection
            @remote._emit 'connection', connection
            @remote = connection

    # emits events on self
    _emit: => EventEmitter::emit.apply @, toArray arguments

    type: 'direct'

bufferEscape = '\u001bBUF'
toBuffer = (value) ->
    if typeof value == 'string' and value.substr(0, bufferEscape.length) == bufferEscape
        return new Buffer value.substr(bufferEscape.length), 'base64'
    else if typeof value == 'object'
        for k, v of value
            if typeof value == 'string' or typeof value == 'object'
                value[k] = toBuffer v
        return value
    else return value

toBase64 = (value) ->
    if value instanceof Buffer then return bufferEscape+value.toString 'base64'
    else if typeof value == 'object'
        for k, v of value
            value[k] = toBase64 v if value instanceof Buffer or typeof value == 'object'
        return value
    else return value

convertArgs = (converter, listener) -> ->
    args = Array::slice.call arguments, 0
    args[i] = converter arg for arg, i in args
    listener.apply @, args

class WebsocketInterface extends Interface
    _on: (event, listener) => @socket.on event, convertArgs(toBuffer, listener)

    _once: (event, listener) => @socket.once event, convertArgs(toBuffer, listener)

    _listen: (@port, options) =>
        options = {} if not options?
        options['log level'] = -1 if not options['log level']?
        @socket = io.listen(@port, options).sockets
        @socket.on 'connection', (socket) => @_emit 'connection', new WebsocketInterface socket

    _send: => convertArgs(toBase64, @socket.emit.bind(@socket)).apply @, toArray(arguments)

    _connect: (remote) =>
        @socket = if typeof remote == 'string' or typeof remote == 'number' then ioc.connect 'ws://'+remote else remote

    type: 'websocket'


module.exports = Interface
module.exports.direct = Interface
module.exports.websocket = WebsocketInterface