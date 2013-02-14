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

    @on 'join', (e, player, state) =>
        handoff = if state.handoff then "(handoff:#{state.handoff}) " else ''
        @info "#{player.username} joined #{handoff}(connector:#{player.connector.id})"

        player.entityId = Math.floor Math.random() * 0xffff

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

        onMovement = (e, packet) ->
            d = player.positionDelta = _.clone player.position
            d[k] = (Number(packet[k]) - Number(v)) || 0 for k,v of d

            # TODO: separate look event
            player.emit 'move', d if d.x or d.y or d.z or d.yaw or d.pitch

        player.on 0xa, onMovement
        player.on 0xb, onMovement
        player.on 0xc, onMovement
        player.on 0xd, onMovement

        player.on 'quit', (e) =>
            @emit 'quit', player

            @info "#{player.username} quit (connector:#{player.connector.id})"

            # TODO: maybe save this stuff periodically while logged in
            player.storage.position = _.pick player.position, 'x', 'y', 'z', 'yaw', 'pitch'
            player.save()

        player.on 'move', (e, d) ->
            player.position[k] = Number(player.position[k]) + Number(v) for k,v of d
            player.position.onGround = Boolean player.position.onGround

        player.on 'move:after', ->
            pos =
                entityId: player.entityId
                x: Math.round player.position.x * 32
                y: Math.round player.position.y * 32
                z: Math.round player.position.z * 32
                yaw: packAngle player.position.yaw
                pitch: packAngle player.position.pitch

            for p in player.region.players
                if p != player
                    p.send 0x22, pos
                    p.send 0x23, entityId: pos.entityId, headYaw: pos.yaw if player.positionDelta.yaw

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

        for p in player.region.players
            if p != player
                p.send 0x14, selfSpawn
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