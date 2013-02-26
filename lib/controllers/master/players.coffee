_ = require 'underscore'

module.exports = ->
  @on 'db.ready:after', =>
    @on 'join', (e, player, res) =>
      @db.findOne 'users', _.pick(player, 'username'), (err, doc) =>
        return @error err if err

        storage = doc?.storage
        player.storage = storage or {
          region: 'main'
          # TODO: handle default region
        }

        server = @peers.servers[0]
        # TODO: find correct server

        res _.pick(server, 'id', 'interfaceType', 'interfaceId'), player

        if not storage
          player.created = Date.now()
          @db.insert 'users', player, (err) => @error err if err

    @on 'peer.connector', (e, connector, connection) =>
      connection.respond 'connection', (res, player) =>
        @emit 'join', player, res