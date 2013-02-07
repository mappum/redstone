Component = require './component'
Interface = require './interface'
mcnet = require 'minecraft-protocol'
_ = require 'underscore'

class Connector extends Component
    constructor: (@master, options) ->
        super()
        
        @clients = []
        @clients.usernames = {}
        @clients.connectionIds = {}

        @servers = []

        # listen for client connections
        @mcserver = mcnet.createServer options
        @mcserver.on 'error', @error
        @mcserver.on 'login', @connection
        @mcserver.on 'listening', =>
            @info "listening for Minecraft connections on port #{options.port or 25565}"
            @emit 'listening'

        # register with master
        @master.request 'init', type: 'connector', (@id) =>

    connection: (connection) =>
        while not connectionId? or @clients.connectionIds[connectionId]?
            connectionId = Math.floor(Math.random() * 0xffffffff).toString(36)

        address = "#{connection.socket.remoteAddress}:#{connection.socket.remotePort}"
        @info "#{connection.username}/#{connectionId} [#{address}] connected"
        connection.on 'close', (id, packet) =>
            @info "#{connection.username}/#{connectionId} [#{address}] disconnected"

        clientJson =
            connectionId: connectionId
            username: connection.username
            ip: connection.socket.remoteAddress

        # request server to forward player connection to
        @master.request 'connection', clientJson, (res) =>
            @connectServer res.serverId, res.interfaceType, res.interfaceId, (server) =>
                client =
                    connection: connection
                    server: server
                    connectionId: connectionId
                    username: connection.username
                    region: res.region

                @clients.push client
                @clients.usernames[client.username.toLowerCase()] = client
                @clients.connectionIds[client.connectionId] = client

                client.connection.on 'close', =>
                    client.server.connection.emit 'quit', client.connectionId
                    @master.emit 'quit', client.connectionId
         
                # when we recieve data from the client, send it to the corresponding server
                client.connection.on 'packet', (packet) =>
                    client.server.connection.emit 'data', client.connectionId, packet.id, packet

                @emit 'join', client
                client.server.connection.emit 'join', _.omit(client, 'connection', 'server'), {}

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
                if client? then client.connection.write id, data

            server.connection.on 'handoff', @getClient (client, server, region) =>
                if client?
                    @connectServer server.id, server.interfaceType, server.interfaceId, (newServer) =>
                        oldServer = client.server
                        @debug "handing off #{client.username}/#{client.connectionId} to server:#{newServer.id}"
                        client.server.connection.emit 'quit', client.connectionId
                        client.server = newServer
                        client.region = region
                        client.server.connection.emit 'join', _.omit(client, 'socket', 'server'), handoff: oldServer.id

        else callback server

    getClient: (cb) => (id) =>
        client = @clients.connectionIds[id]
        args = [client]
        args = args.concat Array::slice.call(arguments, 1)
        cb.apply @, args

module.exports = Connector