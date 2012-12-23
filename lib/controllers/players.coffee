module.exports = ->
    @players = []
    @players.usernames = {}

    @on 'peer.connector', (e, connector, connection) =>
        connection.on 'join', (player) =>
            player.connector = connector
            player.emit = (id, data) -> connection.emit 'data', player.username, id, data
            @emit 'join', player

        connection.on 'quit', (username) =>
            player = @players.usernames[username]
            @emit 'quit', player if player?

    @on 'join', (e, player) =>
        @info "#{player.username} joined (connector:#{player.connector.id})"
        @players.push player
        @players.usernames[player.username] = player

        player.emit 0x1,
            entityId: 0
            levelType: 'default'
            gameMode: 1
            dimension: 0
            difficulty: 0
            maxPlayers: 64

        player.emit 0xd,
            x: 0
            y: 64
            stance: 65.5
            z: 0
            yaw: 0
            pitch: 0
            onGround: false
            
    @on 'quit', (e, player) =>
        @info "#{player.username} quit (connector:#{player.connector.id})"