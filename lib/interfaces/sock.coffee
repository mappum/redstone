Interface = require './interface'
sock = require 'sock'

class SockInterface extends Interface
    _on: (event, listener) ->
        addListener = => @sock.on.call @sock, event, listener
        if not @sock? then @_on 'connected', addListener
        else addListener()

    _once: (event, listener) ->
        addListener = => @sock.once.call @sock, event, listener
        if not @sock? then @_on 'connected', addListener
        else addListener()

    _listen: (@port) =>
        @sock = sock.listen @port
        @sock.on 'connection', (client) =>
            @_emit 'connection', new SockInterface client

    _send: =>
        args = @toArray arguments
        send = => @sock.emit.apply @sock, args

        if not @sock? then @_on 'connected', send
        else send()

    _connect: (remote) =>
        @sock = if remote instanceof sock.Client then remote else sock.connect remote
        @_emit 'connected'

    type: 'sock'

module.exports = SockInterface