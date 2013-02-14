Component = require './component'
Interface = require './interface'
Collection = require './models/collection'
Client = require './models/connector/client'
Server = require './models/connector/server'
mcnet = require 'minecraft-protocol'
_ = require 'underscore'

class Connector extends Component
    constructor: (config, @master) ->
        super config
        
        @clients = new Collection [], indexes: ['username']
        @servers = new Collection

    start: =>
        # load core modules
        @use require '../lib/controllers/connector/data'
        @use require '../lib/controllers/connector/handoff'

        # listen for client connections
        @mcserver = mcnet.createServer @config.connector
        @mcserver.on 'error', @error
        @mcserver.on 'login', @connection
        @mcserver.on 'listening', =>
            @info "listening for Minecraft connections on port #{@config.connector.port or 25565}"
            @emit 'listening'

        # register with master
        @master.request 'init', type: 'connector', (@id) =>

    connection: (connection) =>
        connectionJson =
            username: connection.username
            ip: connection.socket.remoteAddress

        # request server to forward player connection to
        @master.request 'connection', connectionJson, (server, player) =>
            @connect server.id, server.interfaceType, server.interfaceId, (server) =>
                player.server = server
                player.connection = connection
                client = new Client player

                if @clients.get 'username', client.username
                    return client.kick("Someone named '#{client.username}' is already connected.")
                @clients.insert client

                address = "#{client.connection.socket.remoteAddress}:#{client.connection.socket.remotePort}"
                @info "#{client.username}/#{client.id} [#{address}] connected"

                client.on 'quit', =>
                    @info "#{connection.username} [#{address}] disconnected"
                    @clients.remove client
                    @master.emit 'quit', client.id

                @emit 'join', client
                client.start()

    connect: (id, interfaceType, interfaceId, callback) =>
        server = @servers.get id
        if typeof callback != 'function' then callback = ->

        if not server?
            server = new Server
                id: id
                connection: new Interface[interfaceType](interfaceId)
                interfaceId: interfaceId
                interfaceType: interfaceType

            @servers.insert server
            @emit 'connect', server
            server.connect @id, -> callback server

        else callback server

    getClient: (cb) => (id) =>
        client = @clients.get id
        args = [client]
        args = args.concat Array::slice.call(arguments, 1)
        cb.apply @, args

module.exports = Connector