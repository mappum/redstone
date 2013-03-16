_ = require 'underscore'

module.exports = ->
  @on 'db.ready:after', =>
    @db.ensureIndex 'players', {username: 1}

    @on 'join', (e, player, res) =>
      @db.findOne 'players', _.pick(player, 'username'), (err, doc) =>
        return @error err if err

        storage = doc?.storage
        player.storage = storage or {}

        # TODO: get default world from somewhere
        player.storage.world = 'main' if not player.storage.world?
        world = @worlds.get player.storage.world

        if not player.storage.position?
          # TODO: allow spawning in a random spot in an area
          # TODO: distribute spawns across a list of points/areas
          player.storage.position =
            if world.spawn? then _.clone world.spawn
            else
              x: 0
              y: 128
              z: 0
              yaw: 0
              pitch: 0

        chunkX = Math.floor player.storage.position.x / 16
        chunkZ = Math.floor player.storage.position.z / 16
        # TODO: figure out what to do if the chunk is unmapped
        regionId = world.map[chunkX]?[chunkZ]?.region or Math.floor Math.random() * @peers.servers.length
        server = world.servers[regionId]

        res server, player

        if not storage
          player.created = Date.now()
          @db.insert 'players', player, (err) => @error err if err

    @on 'peer.connector', (e, connector, connection) =>
      connection.respond 'connection', (res, player) =>
        @emit 'join', player, res