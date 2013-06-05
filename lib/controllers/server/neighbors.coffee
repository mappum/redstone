_ = require 'underscore'
MapCollection = require '../../models/mapCollection'
Player = require '../../models/server/player'

module.exports = ->

  connectNeighbors = (region) =>
    # TODO: disconnect from neighbors when not needed
    for neighbor in region.neighbors
      do (neighbor) =>
        connect = =>
          @connect neighbor, (server) =>
            neighbor.connection = server.connection

        if neighbor.id > @id and not neighbor.connection?
          setTimeout connect, 2000
        else connect()

  @on 'region:after', (e, region, options) =>
    region.globalPlayers = new MapCollection
      indexes: [{key: 'username', replace: true}]
      cellSize: 16

    broadcastPlayer = (player, connector) ->
      p = _.pick player, 'username', 'position', 'id'
      p.connector = _.omit player.connector, 'connection' if connector
      for neighbor in region.neighbors
        if neighbor.connection?
          neighbor.connection.emit 'player', region.world.id, p

    broadcastRemovePlayer = (player) ->
      p = _.pick player, 'username', 'position', 'id'
      for neighbor in region.neighbors
        if neighbor.connection?
          neighbor.connection.emit 'removePlayer', region.world.id, p

    connectNeighbors region

    region.players.on 'insert:after', (e, player) =>
      broadcastPlayer player, true

      broadcastInterval = setInterval ->
        broadcastPlayer player
      , 5000

      player.on 'leave:after', ->
        clearInterval broadcastInterval
        broadcastRemovePlayer player

    region.on 'remap:after', (e) =>
      connectNeighbors region
      broadcastPlayer player, true for player in region.players.models

  @on 'peer.server', (e, server, connection) =>
    for region in @regions.models
      for neighbor in region.neighbors
        if neighbor.id == server.id
          neighbor.connection = connection
          break

    connection.on 'player', (regionId, p) =>
      region = @regions.get 'world.id', regionId
      player = region.globalPlayers.get p.id

      if not player?
        @connect p.connector, (connector) =>
          player = new Player p
          player.connector = connector

          region.globalPlayers.insert player

      else if not region.players.get p.id
        _.extend player, p
        player.emit 'move'

    connection.on 'removePlayer', (regionId, p) =>
      region = @regions.get 'world.id', regionId
      player = region.globalPlayers.get p.id
      region.globalPlayers.remove p.id if player?