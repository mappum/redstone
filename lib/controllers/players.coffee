Player = require '../models/player'
_ = require 'underscore'

packAngle = (degrees) ->
    Math.floor (degrees % 360 + if degrees < 0 then 360 else 0) * (0xff / 360)

module.exports = ->
    @players = []
    @players.usernames = {}
    @players.connectionIds = {}

    getPlayer = (fn) =>
        return (connectionId) =>
            player = @players.connectionIds[connectionId]
            args = Array::slice.call arguments, 1
            args.splice 0, 0, player
            fn.apply @, args if player?

    @on 'peer.connector', (e, connector, connection) =>
        connection.on 'join', (player, state) =>
            player.connector = connector
            player = new Player player
            @players.connectionIds[player.connectionId] = player

            if @players.usernames[player.username]?
                player.kick "Someone named '#{player.username}' is already connected."
                @players.connectionIds[player.connectionId] = undefined
                return

            @players.push player
            @players.usernames[player.username] = player

            @emit 'join', player, state

        connection.on 'quit', getPlayer (player) =>
            @players.splice @players.indexOf(player), 1
            @players.usernames[player.username] = undefined
            @players.connectionIds[player.connectionId] = undefined

            player.emit 'quit' if not player.kicked

        connection.on 'data', getPlayer (player, id, data) =>
            player.emit 'data', id, data
            player.emit id, data

    @on 'join', (e, player, state) =>
        handoff = if state.handoff then "(handoff:#{state.handoff}) " else ''
        @info "#{player.username} joined #{handoff}(connector:#{player.connector.id})"

        player.entityId = Math.floor Math.random() * 0xffff

        # TODO: get initial position from state
        player.position =
            x: 0
            y: 256
            z: 0
            stance: 257.8
            yaw: 0
            pitch: 0
            onGround: false

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
            @info "#{player.username} quit (connector:#{player.connector.id})"
            @emit 'quit', player

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
            metaData: 0

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
                    metaData: 0