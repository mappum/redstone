Base = require './base'
mcnet = require 'minecraft-net'

class Connector extends Base
    constructor: (@master, options) ->
        super()
        
        @connections = []
        @connections.usernames = {}

        # listen for client connections
        @mcserver = mcnet.createServer options, @connection
        @mcserver.listen options.port or 25565, =>
            @info "listening for Minecraft connections on port #{@mcserver.port}"
            @emit 'listening'

    connection: (socket, handshake) =>
        client = handshake
        client.socket = socket
        # TODO: contact master to get destination server
        #client.server =

        ###

        @clients.push client
        @clients.usernames[client.username.toLowerCase()] = client

        address = "#{client.client.socket.remoteAddress}:#{client.client.socket.remotePort}"
        @info "#{client.username}[#{address}] connected"

        client.socket.on 'close', (id, packet) =>
            @info "#{client.username}[#{address}] disconnected"
            # TODO: tell master about leave
            # TODO: close connection to server
 
        # when we recieve data from the client, send it to the corresponding server
        client.socket.on 'data', (id, packet) =>
            client.server.emit 'data', client.username, id, packet

        @emit 'client', client
        client.server.emit 'client', client

        ###

module.exports = Connector