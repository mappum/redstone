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
        address = "#{socket.socket.remoteAddress}:#{socket.socket.remotePort}"
        @info "#{handshake.username} [#{address}] connected"
        socket.on 'close', (id, packet) =>
            @info "#{handshake.username} [#{address}] disconnected"
            
        while not handshake.connectionId? or @clients.connectionIds[handshake.connectionId]?
            handshake.connectionId = Math.floor(Math.random() * 0xffffffff).toString(36)

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

            @emit 'join', client
            client.server.emit 'join', handshake

module.exports = Connector