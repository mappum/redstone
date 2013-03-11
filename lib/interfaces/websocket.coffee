Interface = require './interface'
io = require 'socket.io'
ioc = require 'socket.io-client'

bufferEscape = '\u001b'

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

    _send: => convertArgs(toBase64, @socket.emit.bind(@socket)).apply @, @toArray(arguments)

    _connect: (remote) =>
        @socket = if typeof remote == 'string' or typeof remote == 'number' then ioc.connect 'ws://'+remote else remote

    type: 'websocket'

module.exports = WebsocketInterface