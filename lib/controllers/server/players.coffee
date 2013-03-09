Player = require '../../models/server/player'
Collection = require '../../models/collection'
_ = require 'underscore'

PLAYER_ENTITY_PREFIX = 1 << 28

module.exports = ->
    @players = new Collection [], indexes: ['username']

    getPlayer = (fn) =>
        return (id) =>
            player = @players.get id
            args = Array::slice.call arguments, 1
            args.splice 0, 0, player
            fn.apply @, args if player?

    @on 'peer.connector', (e, connector, connection) =>
        connection.on 'join', (player, state) =>
            player.connector = connector
            player = new Player player

            if @players.get('username', player.username)?
                player.kick "Someone named '#{player.username}' is already connected."
                return

            @players.insert player
            @emit 'join', player, state

        connection.on 'quit', getPlayer (player) =>
            @players.remove player
            player.emit 'quit' if not player.kicked

        connection.on 'data', getPlayer (player, id, data) =>
            player.emit 'data', id, data
            player.emit id, data

    @on 'join:before', (e, player, options) =>
        handoff = if options.handoff then "(handoff:#{options.handoff}) " else ''
        @info "#{player.username} joined #{handoff}(connector:#{player.connector.id})"

        player.entityId = PLAYER_ENTITY_PREFIX | Math.floor Math.random() * 0xfffffff

        onReady = ->
            player.emit 'ready'
            player.off 0xa, onReady
            player.off 0xb, onReady
            player.off 0xc, onReady
            player.off 0xd, onReady
        player.on 0xa, onReady
        player.on 0xb, onReady
        player.on 0xc, onReady
        player.on 0xd, onReady

    @on 'join:after', (e, player, options) ->
        worldMeta =
            levelType: 'flat'
            gameMode: 1
            dimension: 0
            difficulty: 0
            maxPlayers: 64
        _.extend worldMeta, player.region.world.meta if player.region.world.meta?

        # player just joined
        if not options.handoff
            worldMeta.entityId = player.entityId
            player.send 0x1, worldMeta

        # transparent handoff
        else if options.handoff.transparent
            # TODO: do server handoff stuff

        # hard handoff
        else
            # change dimension, then go back in order to make sure client unloads everything
            fakeWorldMeta = _.clone worldMeta
            fakeWorldMeta.dimension++
            fakeWorldMeta.dimension = 0 if fakeWorldMeta.dimension > 1
            player.send 0x9, fakeWorldMeta
            player.send 0x9, worldMeta

    @on 'update:before', (e, data) =>
        data.players = @players.length
