Player = require '../../models/server/player'
Collection = require '../../models/collection'
_ = require 'underscore'

packAngle = (degrees) ->
    degrees = degrees % 360 + if degrees < 0 then 360 else 0
    Math.floor (degrees - if degrees > 180 then 360 else 0) * (0xff / 360)

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

        # TODO: get a real spawn point
        spawn =
            x: 0
            y: 256
            z: 0
            yaw: 0
            pitch: 0

        player.position = player.storage.position or _.clone spawn
        player.position.stance = 257.8
        player.position.onGround = false


    @on 'join:after', (e, player, state) =>
        emitMoving = -> player.emit 'moving'

        onMovement = (e, packet) ->
            d = player.positionDelta = _.clone player.position
            d[k] = (Number(packet[k]) - Number(v)) || 0 for k,v of d

            moved = Math.abs(d.x) > 0.01 or Math.abs(d.y) > 0.01 or Math.abs(d.z) > 0.01
            looked = d.yaw or d.pitch

            if moved or looked
                player.position[k] = Number(player.position[k]) + Number(v) for k,v of d
                player.position.onGround = Boolean player.position.onGround

            player.emit 'look', d if looked

            if moved
                if player.stopped
                    player.stopped = false
                    player.movingInterval = setInterval emitMoving, 1000 if not player.movingInterval
                    player.emit 'start'
                player.emit 'move', d
            else if not player.stopped
                player.stopped = true
                clearInterval player.movingInterval
                player.movingInterval = null
                player.emit 'stop'

        player.on 0xb, onMovement
        player.on 0xc, onMovement
        player.on 0xd, onMovement

        player.on 'quit', (e) =>
            @emit 'quit', player

            @info "#{player.username} quit (connector:#{player.connector.id})"

            # TODO: maybe save this stuff periodically while logged in
            player.storage.position = _.pick player.position, 'x', 'y', 'z', 'yaw', 'pitch'
            player.save()

        options =
            radius: 64
            exclude: [player]

        player.on 'look', (e, d) ->
            look =
                entityId: player.entityId
                yaw: packAngle player.position.yaw
                pitch: packAngle player.position.pitch
            headYaw = entityId: player.entityId, headYaw: look.yaw
            
            player.region.send player.position, options, 0x20, look
            player.region.send player.position, options, 0x23, headYaw

        player.on 'move:after', ->
            pos =
                entityId: player.entityId
                x: Math.round player.position.x * 32
                y: Math.round player.position.y * 32
                z: Math.round player.position.z * 32
                yaw: packAngle player.position.yaw
                pitch: packAngle player.position.pitch

            player.region.send player.position, options, 0x22, pos

        if not state.handoff
            player.send 0x1,
                entityId: player.entityId
                levelType: 'default'
                gameMode: 1
                dimension: 0
                difficulty: 0
                maxPlayers: 64
        else
            # change dimension in order to make sure client unloads everything
            player.send 0x9,
                dimension: 1
                difficulty: 0
                gameMode: 1
                worldHeight: 256
                levelType: 'default'
            player.send 0x9,
                dimension: 0
                difficulty: 0
                gameMode: 1
                worldHeight: 256
                levelType: 'default'

        player.send 0xd, player.position

        selfSpawn =
            entityId: player.entityId
            name: player.username
            x: Math.floor player.position.x * 32
            y: Math.floor player.position.y * 32
            z: Math.floor player.position.z * 32
            yaw: packAngle player.position.yaw
            pitch: packAngle player.position.pitch
            currentItem: 0
            metadata: [
                {key: 0, type: 'byte', value: 0}
                {key: 8, type: 'int', value: 0}
            ]

        player.region.send player.position, {radius: 64, exclude: [player]}, 0x14, selfSpawn
        for p in player.region.players.getRadius player, 64
            if p != player
                player.send 0x14,
                    entityId: p.entityId
                    name: p.username
                    x: Math.floor p.position.x * 32
                    y: Math.floor p.position.y * 32
                    z: Math.floor p.position.z * 32
                    yaw: packAngle p.position.yaw
                    pitch: packAngle p.position.pitch
                    currentItem: 0
                    metadata: [
                        {key: 0, type: 'byte', value: 0}
                        {key: 8, type: 'int', value: 0}
                    ]