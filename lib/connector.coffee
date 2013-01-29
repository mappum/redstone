Component = require './component'
Interface = require './interface'
mcnet = require 'minecraft-net'
_ = require 'underscore'

class Connector extends Component
    constructor: (@master, options) ->
        super()
        
        @clients = []
        @clients.usernames = {}
        @clients.connectionIds = {}

        @servers = []

        # listen for client connections
        @mcserver = mcnet.createServer options, @connection
        @mcserver.on 'error', @error        
        @mcserver.listen options.port or 25565, =>
            @info "listening for Minecraft connections on port #{@mcserver.port}"
            @emit 'listening'

        # register with master
        @master.request 'init', type: 'connector', (@id) =>

    connection: (socket, handshake) =>
        while not handshake.connectionId? or @clients.connectionIds[handshake.connectionId]?
            handshake.connectionId = Math.floor(Math.random() * 0xffffffff).toString(36)

        address = "#{socket.socket.remoteAddress}:#{socket.socket.remotePort}"
        @info "#{handshake.username}/#{handshake.connectionId} [#{address}] connected"
        socket.on 'close', (id, packet) =>
            @info "#{handshake.username}/#{handshake.connectionId} [#{address}] disconnected"

        # request server to forward player connection to
        @master.request 'connection', handshake, (res) =>
            @connectServer res.serverId, res.interfaceType, res.interfaceId, (server) =>
                client = handshake
                client.socket = socket
                client.server = @servers[res.serverId]
                client.region = res.region

                @clients.push client
                @clients.usernames[client.username.toLowerCase()] = client
                @clients.connectionIds[client.connectionId] = client

                client.socket.on 'close', =>
                    client.server.connection.emit 'quit', client.connectionId
                    @master.emit 'quit', client.connectionId
         
                # when we recieve data from the client, send it to the corresponding server
                client.socket.on 'data', (packet) =>
                    client.server.connection.emit 'data', client.connectionId, packet.id, packet.data

                @emit 'join', client
                client.server.connection.emit 'join', _.omit(client, 'socket', 'server'), {}

    connectServer: (id, interfaceType, interfaceId, callback) =>
        server = @servers[id]
        if typeof callback != 'function' then callback = ->

        if not server?
            # TODO: make a server model
            server = @servers[id] =
                id: id
                connection: new Interface[interfaceType](interfaceId)
                interfaceId: interfaceId
                interfaceType: interfaceType

            server.connection.request 'init',
                type: 'connector'
                id: @id,
                -> callback server

            server.connection.on 'data', @getClient (client, id, data) =>
                if client? then client.socket.write id, data

            server.connection.on 'handoff', @getClient (client, server, region) =>
                if client?
                    @connectServer server.id, server.interfaceType, server.interfaceId, (newServer) =>
                        @debug "handing off #{client.username}/#{client.connectionId} to server:#{newServer.id}"
                        client.server.connection.emit 'quit', client.connectionId
                        client.server = newServer
                        client.region = region
                        client.server.connection.emit 'join', _.omit(client, 'socket', 'server'), handoff: true

        else callback server

    getClient: (cb) => (connectionId) =>
        client = @clients.connectionIds[connectionId]
        args = [client]
        args = args.concat Array::slice.call(arguments, 1)
        cb.apply @, args

module.exports = Connector