os = require 'os'
sock = require 'sock'
EventStack = require './eventstack'
Collection = require './models/collection'

class Component extends EventStack
  constructor: (@config, control, master) ->
    super()

    @peers = new Collection
    @peers.connectors = new Collection
    @peers.servers = new Collection

    # listen for control connections from peers
    @control = sock.listen control
    @control.on 'connection', @onConnection

    #if a master is specified, connect to it
    @master = sock.connect master if master?

  log: (level, message) => @emit 'log', level, message
  debug: (message) => @log 'debug', message
  info: (message) => @log 'info', message
  warn: (message) => @log 'warn', message
  error: (message) => @log 'error', message

  use: (module) =>
    args = [@config]

    if typeof module == 'function' then module.apply @, args
    else if Array.isArray module then m.apply @, args for m in module

  start: ->
    # tell the master we are ready
    @master.request 'init',
      type: @type
      port: @control.port,
      (@id) =>
        @emit 'ready'

    # send stats to master periodically
    lastUpdate = 0
    updateMaster = =>
      data = 
        loadavg: os.loadavg()
        uptime: os.uptime()
        totalmem: os.totalmem()
        freemem: os.freemem()
        cpus: os.cpus().length
      @emit 'update', data, lastUpdate
      @master.emit 'update', data
      lastUpdate = Date.now()

    updateMaster()
    @updateMasterInterval = setInterval updateMaster, 10 * 1000

  onConnection: (connection) =>
    # when a peer connects, wait for a 'init' request
    connection.respond 'init', (res, options) =>
      peer = options or {}
      peer.connection = connection
      peer.address = "#{connection.remoteAddress}:#{peer.port}"

      # add peer to collections
      @peers.insert peer
      @peers[options.type+'s'].insert peer

      @info "incoming connection from #{options.type}:#{peer.id} (#{peer.address})"

      # answer peer with its id
      res peer.id

      @emit 'peer', peer, connection
      @emit 'peer.'+options.type, peer, connection

      connection.on 'disconnect', =>
        @peers.remove peer
        @peers[options.type+'s'].remove peer

        @info "#{options.type}:#{peer.id} disconnected"

  # connect to a peer (not master), or get the connection if already connected
  connect: (p, cb) ->
    if typeof cb != 'function' then cb = ->

    peer = @peers.get p.id

    # not connected, make a new connection
    if not peer?
      peer = p
      peer.connection = sock.connect peer.address

      # make an 'init' request so peer will handle connection
      peer.connection.request 'init',
        type: @type
        id: @id
        port: @control.port,
        =>
          @peers.insert peer
          @peers[p.type+'s'].insert peer
          @emit 'connect', peer
          @emit 'connect.'+p.type, peer
          @emit 'peer', peer, peer.connection
          @emit 'peer.'+p.type, peer, peer.connection

          cb peer

    # already connected, return the connection
    else cb peer

module.exports = Component