Model = require '../model'
MapCollection = require '../mapCollection'
Player = require './player'
_ = require 'underscore'

class Region extends Model
  constructor: (options) ->
    super()
    options = options or {}
    @[k] = v for k,v of options

    if not @tickInterval? then @tickInterval = 1000 / 20

    @ticks = 0
    @players = new MapCollection {indexes: ['username'], cellSize: 16}

    @update()

  start: ->
    if not @tickTimer
      @tickTimer = setInterval @tick.bind(@), @tickInterval

  stop: ->
    clearInterval @tickTimer
    @tickTimer = null

  tick: ->
    @emit 'tick'
    @ticks++

  send: (position, options, id, data) ->
    idIndex = 2
    if typeof position == 'number'
      id = position
      data = options
      position = null
      options = null
      idIndex = 0
    else if typeof options == 'number'
      data = id
      id = options
      options = null
      idIndex = 1

    options = options or
      radius: 32
      exclude: null

    players = if not position then @players.models else @players.getRadius position, options.radius
    players = _.difference players, options.exclude if options.exclude

    connectors = {}
    for player in players
      connector = connectors[player.connector.id]
      if not connector?
        connector = connectors[player.connector.id] =
          players: [player.id]
          connector: player.connector
      else connector.players.push player.id

    c.connector.connection.emit 'data', c.players, id, data for cId, c of connectors

  # recalculates list of chunks, neighbors, etc after a remap
  update: ->
    @chunkList = []
    @chunkList.push chunk for chunk in @assignment if @assignment?

    # TODO: maybe add all regions in range, rather than bordering neighbors
    neighbors = {}
    checkNeighbor = (x, z) =>
      regionId = @world.map.get(x, z)?.region
      if regionId? and regionId != @regionId and not neighbors[regionId]?
        neighbors[regionId] = true

    for chunk in @chunkList
      checkNeighbor chunk.x+1, chunk.z
      checkNeighbor chunk.x-1, chunk.z
      checkNeighbor chunk.x, chunk.z+1
      checkNeighbor chunk.x, chunk.z-1

    @neighbors = []
    for regionId of neighbors
      @neighbors.push _.clone @world.servers[regionId]

module.exports = Region