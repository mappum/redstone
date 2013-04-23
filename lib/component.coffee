EventStack = require './eventstack'
Collection = require './models/collection'

class Component extends EventStack
  constructor: (@config, @interface) ->
    super()

    @peers = new Collection
    @peers.connectors = new Collection
    @peers.servers = new Collection

    # listen for connections from servers/connectors
    @interface.on 'connection', @connection

  log: (level, message) => @emit 'log', level, message
  debug: (message) => @log 'debug', message
  info: (message) => @log 'info', message
  warn: (message) => @log 'warn', message
  error: (message) => @log 'error', message

  use: (module) =>
    args = [@config]

    if typeof module == 'function' then module.apply @, args
    else if Array.isArray module then m.apply @, args for m in module

  connection: (connection) =>
    connection.respond 'init', (res, options) =>
      peer = options or {}
      peer.connection = connection

      if peer.interfaceType?
        if peer.interfaceType == 'sock'
          address = peer.connection.sock.socket.remoteAddress
          peer.interfaceId = "#{address}:#{peer.port}"
        else if peer.interfaceType == 'websocket'
          address = peer.connection.socket.handshake.address
          peer.interfaceId = "#{address.address}:#{peer.port}"
        else if peer.interfaceType == 'direct'
          peer.interfaceId = peer.port

      @peers.insert peer
      @peers[options.type+'s'].insert peer

      @info "incoming connection from #{options.type}:#{peer.id}"

      res peer.id

      @emit 'peer', peer, connection
      @emit 'peer.'+options.type, peer, connection

      connection.on 'disconnect', =>
        @peers.remove peer
        @peers[options.type+'s'].remove peer

        @info "#{options.type}:#{peer.id} disconnected"

  connect: (p, type, cb) =>
    if typeof type == 'function'
      cb = type
      type = null
    else if typeof cb != 'function' then cb = ->
    if typeof type != 'string' then type = p.type or 'server'

    peer = @peers[type+'s'].get p.id

    if not peer?
      peer =
        id: p.id
        connection: new (require "./interfaces/#{p.interfaceType}")(p.interfaceId)
        interfaceId: p.interfaceId
        interfaceType: p.interfaceType

      peer.connection.request 'init',
        type: @type
        id: @id
        interfaceType: @interface.type
        port: @interface.port,
        =>
          @peers.insert peer
          @peers[type+'s'].insert peer
          @emit 'connect', peer
          @emit 'connect.'+type, peer
          @emit 'peer', peer, peer.connection
          @emit 'peer.'+type, peer, peer.connection

          cb peer

    else cb peer

module.exports = Component