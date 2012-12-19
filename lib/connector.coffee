Base = require './base'
Interface = require './interface'
mcnet = require 'minecraft-net'

class Connector extends Base
    constructor: (@master, options) ->
        super()
        
        @clients = []
        @clients.usernames = {}

        # listen for client connections
        @mcserver = mcnet.createServer options, @connection
        @mcserver.listen options.port or 25565, =>
            @info "listening for Minecraft connections on port #{@mcserver.port}"
            @emit 'listening'

    connection: (socket, handshake) =>
        address = "#{socket.socket.remoteAddress}:#{socket.socket.remotePort}"
        @info "#{handshake.username} [#{address}] connected"
        socket.on 'close', (id, packet) =>
            @info "#{handshake.username} [#{address}] disconnected"

        @master.request 'connection', handshake, (server) =>
            client = handshake
            client.socket = socket
            client.server = new Interface(server)
            ###

            @clients.push client
            @clients.usernames[client.username.toLowerCase()] = client
            client.socket.on 'close', (id, packet) =>
                client.server.emit ''
                @master.emit 'leave', client.username
     
            # when we recieve data from the client, send it to the corresponding server
            client.socket.on 'data', (id, packet) =>
                client.server.emit 'data', client.username, id, packet

            @emit 'client', client
            client.server.emit 'client', client
            ###

module.exports = Connector