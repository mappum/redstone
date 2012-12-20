Component = require './component'
Interface = require './interface'
mcnet = require 'minecraft-net'
_ = require 'underscore'

class Connector extends Component
    constructor: (@master, options) ->
        super()
        
        @clients = []
        @clients.usernames = {}

        @servers = []

        # listen for client connections
        @mcserver = mcnet.createServer options, @connection
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

        # request server to forward player connection to
        @master.request 'connection', handshake, (res) =>
            if not @servers[res.serverId]
                server = @servers[res.serverId] = new Interface[res.interfaceType](res.interface)
                server.request 'init',
                    type: 'connector'
                    id: @id,
                    =>
                server.on 'data', (username, id, data) =>
                    client = @clients.usernames[username]
                    if client? then client.socket.write id, data

            client = _.clone handshake
            client.socket = socket
            client.server = @servers[res.serverId]

            @clients.push client
            @clients.usernames[client.username.toLowerCase()] = client
            client.socket.on 'close', =>
                client.server.emit 'leave', client.username
                @master.emit 'leave', client.username
     
            # when we recieve data from the client, send it to the corresponding server
            client.socket.on 'data', (packet) =>
                client.server.emit 'data', client.username, packet.id, packet.data

            @emit 'join', client
            client.server.emit 'join', handshake

module.exports = Connector