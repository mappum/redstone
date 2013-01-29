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

    log: (level, message) => @emit 'log', level, message
    debug: (message) => @log 'debug', message
    info: (message) => @log 'info', message
    warn: (message) => @log 'warn', message
    error: (message) => @log 'error', message

    connection: (connection) =>
        connection.respond 'init', (res, options) =>
            peer = options or {}
            peer.connection = connection
            peer.id = Math.floor(Math.random() * 0xffffffff).toString(36) while not peer.id or @peers.all[peer.id]?

            if peer.interfaceType?
                if peer.interfaceType == 'websocket'
                    address = peer.connection.socket.handshake.address
                    peer.interfaceId = "#{address.address}:#{peer.port}"
                else if peer.interfaceType == 'direct'
                    peer.interfaceId = peer.port

            @peers[options.type+'s'].push peer
            @peers.all[peer.id] = peer

            @info "incoming connection from #{options.type}:#{peer.id}"

            res peer.id

            @emit 'peer', peer, connection
            @emit 'peer.'+options.type, peer, connection

            connection.on 'disconnect', =>
                @peers[options.type+'s'].splice @peers[options.type+'s'].indexOf(peer), 1
                @peers.all[peer.id] = undefined

                @info "#{options.type}:#{peer.id} disconnected"
            

module.exports = Component