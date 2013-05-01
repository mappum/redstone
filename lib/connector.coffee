Component = require './component'
Collection = require './models/collection'
Client = require './models/connector/client'
mcnet = require 'minecraft-protocol'
_ = require 'underscore'

class Connector extends Component
  constructor: (config, port, master) ->
    @type = 'connector'
    super config, port, master
    
    @clients = new Collection [], indexes: ['username']

    @stats = {}

  start: ->
    # load core modules
    @use require '../lib/controllers/connector/data'
    @use require '../lib/controllers/connector/handoff'

    # listen for client connections
    @mcserver = mcnet.createServer @config.connector
    @mcserver.on 'error', @error
    @mcserver.on 'login', @onPlayerConnect
    @mcserver.on 'listening', =>
      @info "listening for Minecraft connections on port #{@config.connector.port or 25565}"
      @emit 'listening'
    
    # listen for master updates
    @master.on 'update', (data) =>
      @stats = _.extend @stats, data
      @mcserver.playerCount = @stats.players

    super()

  onPlayerConnect: (connection) =>
    connectionJson =
      username: connection.username

    # request server to forward player connection to
    @master.request 'join', connectionJson, (server, player) =>
      @connect server, (server) =>
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

  getClient: (id) -> @clients.get id

  getClients: (cb) => (ids) =>
    if ids instanceof Array
      clients = []
      clients.push @getClient id for id in ids
    else
      clients = [@getClient ids]

    args = [clients]
    cb.apply @, args.concat Array::slice.call(arguments, 1)

module.exports = Connector