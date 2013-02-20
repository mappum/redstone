Player = require '../../models/server/player'
Collection = require '../../models/collection'

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

    @on 'join:before', (e, player, state) =>
        handoff = if state.handoff then "(handoff:#{state.handoff}) " else ''
        @info "#{player.username} joined #{handoff}(connector:#{player.connector.id})"

        player.entityId = Math.floor Math.random() * 0xffff

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
