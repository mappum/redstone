Player = require '../models/player'

module.exports = ->
    @players = []
    @players.usernames = {}

    getPlayer = (fn) =>
        return (username) =>
            args = Array::slice.call arguments, 1
            args.splice 0, 0, @players.usernames[username.toLowerCase()]
            fn.apply @, args

    @on 'peer.connector', (e, connector, connection) =>
        connection.on 'join', (player) =>
            player.connector = connector
            player = new Player player

            @players.push player
            @players.usernames[player.username.toLowerCase()] = player

            @emit 'join', player

        connection.on 'quit', getPlayer (player) =>
            @emit 'quit', player

        connection.on 'data', getPlayer (player, id, data) =>
            player.emit 'data', id, data
            player.emit 'data.0x'+id.toString 16, data

    @on 'join', (e, player) =>
        @info "#{player.username} joined (connector:#{player.connector.id})"

        player.send 0x1,
            entityId: 0
            levelType: 'default'
            gameMode: 1
            dimension: 0
            difficulty: 0
            maxPlayers: 64

        player.send 0xd,
            x: 0
            y: 64
            stance: 65.5
            z: 0
            yaw: 0
            pitch: 0
            onGround: false
            
    @on 'quit', (e, player) =>
        @info "#{player.username} quit (connector:#{player.connector.id})"