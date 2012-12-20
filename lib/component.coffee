EventStack = require './eventstack'

class Component extends EventStack
    constructor: (@interface) ->
        super()

        if @interface?
            @peers = {}
            @peers.connectors = []
            @peers.servers = []
            @peers.all = {}

            # listen for connections from servers/connectors
            @interface.on 'connection', @connection

    log: (level, message) => @emit 'log', level, message, @meta
    debug: (message) => @log 'debug', message
    info: (message) => @log 'info', message
    warn: (message) => @log 'warn', message
    error: (message) => @log 'error', message

    connection: (connection) =>
        connection.respond 'init', (res, options) =>
            peer = options or {}
            peer.connection = connection

            id = Math.floor(Math.random() * 0xffffffff).toString(36) while not id or @peers.all[id]?

            @peers[options.type+'s'].push peer
            @peers.all[id] = peer

            @info "incoming connection from #{options.type}:#{id}"

            res id: id

            @emit 'peer', peer, connection
            @emit 'peer.'+options.type, peer, connection

module.exports = Component