EventEmitter = require('events').EventEmitter

toArray = (a) -> Array.prototype.slice.call a
removeId = (listener) -> => listener.apply @, toArray(arguments).slice 1

class Interface extends EventEmitter
    toArray: toArray

    constructor: (remote) ->
        @_connect remote if remote?

    # sends an event to the remote interface
    emit: (event) =>
        if event != 'newListener'
            # first argument is request id, insert null
            args = @toArray arguments
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
        args = @toArray arguments
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
                    args = @toArray arguments
                    args.splice 0, 0, id
                    @_send.apply @, args

                # insert response function and call listener
                args = @toArray arguments
                args.splice 0, 1, res
                listener.apply @, args

    # tells this interface to listen for remote interface connections
    listen: =>
        @listening = true
        @_listen.apply @, @toArray arguments
        @

    # setup for listening
    _listen: =>
        @connections = []

    # registers an event listener
    _on: (event, listener) => EventEmitter::on.call @, event, listener

    # registers an event listener, then removes listener
    _once: (event, listener) => EventEmitter::once.call @, event, listener

    # does the actual sending to the remote interface
    _send: => @remote._emit.apply @remote, @toArray arguments

    # connects to remote
    _connect: (@remote) =>
        if @remote.listening
            connection = new Interface @
            @remote.connections.push connection
            @remote._emit 'connection', connection
            @remote = connection

    # emits events on self
    _emit: => EventEmitter::emit.apply @, @toArray arguments

    type: 'interface'

module.exports = Interface