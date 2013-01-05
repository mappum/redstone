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
            if not @servers[res.serverId]
                server = @servers[res.serverId] = new Interface[res.interfaceType](res.interface)
                server.request 'init',
                    type: 'connector'
                    id: @id,
                    =>
                server.on 'data', (connectionId, id, data) =>
                    client = @clients.connectionIds[connectionId]
                    if client? then client.socket.write id, data

            client = _.clone handshake
            client.socket = socket
            client.server = @servers[res.serverId]

            @clients.push client
            @clients.usernames[client.username.toLowerCase()] = client
            @clients.connectionIds[client.connectionId] = client

            client.socket.on 'close', =>
                client.server.emit 'quit', client.connectionId
                @master.emit 'quit', client.connectionId
     
            # when we recieve data from the client, send it to the corresponding server
            client.socket.on 'data', (packet) =>
                client.server.emit 'data', client.connectionId, packet.id, packet.data

            @emit 'join', client, res.state
            client.server.emit 'join', handshake, res.state

module.exports = Connector