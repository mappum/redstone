module.exports = ->
    @on 'join', (e, player) =>
        @info "#{player.username} joined (connector: #{player.connector.remoteAddress})"

        #player.client.on 'close', =>
        #    @info "#{player.username} quit"

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