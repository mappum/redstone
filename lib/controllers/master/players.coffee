_ = require 'underscore'

module.exports = ->
  @on 'db.ready:after', =>
    @db.ensureIndex 'players', {username: 1}

    @on 'join', (e, player, res) =>
      @db.findOne 'players', _.pick(player, 'username'), (err, doc) =>
        return @error err if err

        storage = doc?.storage
        player.storage = storage or
          world: 'main'

        position =
          if storage? and storage.position? then storage.position
          else
            # TODO: allow spawning in a random spot in an area
            # TODO: distribute spawns across a list of points/areas
            # TODO: get a real spawn point/area from world data
            x: 0
            y: 128
            z: 0
            yaw: 0
            pitch: 0

        server = @peers.servers.get 0

        res _.pick(server, 'id', 'interfaceType', 'interfaceId'), player

        if not storage
          player.created = Date.now()
          @db.insert 'players', player, (err) => @error err if err

    @on 'peer.connector', (e, connector, connection) =>
      connection.respond 'connection', (res, player) =>
        @emit 'join', player, res