module.exports = ->

    @on 'join', (e, player, connector) =>
        @info "#{player.username} joined (connector: #{connector.remoteAddress})"

        player.client.on 'close', =>
            @info "#{player.username} quit"

        player.client.write 0x1,
            entityId: 0
            levelType: 'default'
            gameMode: 1
            dimension: 0
            difficulty: 0
            maxPlayers: 64

        player.client.write 0xd,
            x: 0
            y: 64
            stance: 65.5
            z: 0
            yaw: 0
            pitch: 0
            onGround: false