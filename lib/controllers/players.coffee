Player = require '../models/player'
_ = require 'underscore'

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

            if @players.usernames[player.userId]?
                player.kick "Someone named '#{player.username}' is already connected."
                @players.connectionIds[player.connectionId] = undefined
                return

            @players.push player
            @players.usernames[player.userId] = player

            @emit 'join', player, state

        connection.on 'quit', getPlayer (player) =>
            if not player.kicked
                @emit 'quit', player
                @players.splice @players.indexOf(player), 1
                @players.usernames[player.userId] = undefined
                @players.connectionIds[player.connectionId] = undefined

        connection.on 'data', getPlayer (player, id, data) =>
            player.emit 'data', id, data
            player.emit id, data

    @on 'join', (e, player, state) =>
        @info "#{player.username} joined (connector:#{player.connector.id})"

        player.entityId = Math.floor Math.random() * 0xffff

        # TODO: get initial position from state
        player.position =
            x: 0
            y: 64
            z: 0
            stance: 65.8
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

        player.on 'move', (e, d) ->
            player.position[k] = Number(player.position[k]) + Number(v) for k,v of d
            player.position.onGround = Boolean player.position.onGround

        # TODO: get from state
        player.send 0x1,
            entityId: player.entityId
            levelType: 'default'
            gameMode: 1
            dimension: 0
            difficulty: 0
            maxPlayers: 64

        player.send 0xd, player.position

        selfSpawn =
            entityId: player.entityId
            name: player.username
            x: Math.floor player.position.x * 32
            y: Math.floor player.position.y * 32
            z: Math.floor player.position.z * 32
            yaw: 0#(Math.abs Math.floor (player.position.yaw % 360)) * (255 / 360)
            pitch: 0#(Math.abs Math.floor (player.position.pitch % 360)) * (255 / 360)
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
                    yaw: 0#(Math.abs Math.floor (p.position.yaw % 360)) * (255 / 360)
                    pitch: 0#(Math.abs Math.floor (p.position.pitch % 360)) * (255 / 360)
                    currentItem: 0
                    metaData: 0

        setInterval ->
            pos =
                entityId: player.entityId
                x: Math.round player.position.x * 32
                y: Math.round player.position.y * 32
                z: Math.round player.position.z * 32
                yaw: 0#(Math.abs Math.floor (player.position.yaw % 360)) * (255 / 360)
                pitch: 0#(Math.abs Math.floor (player.position.pitch % 360)) * (255 / 360)

            for p in player.region.players
                if p != player
                    #console.log "#{p.entityId} -> #{player.entityId}"
                    p.send 0x22, pos
        , 100
            
    @on 'quit', (e, player) =>
        @info "#{player.username} quit (connector:#{player.connector.id})"