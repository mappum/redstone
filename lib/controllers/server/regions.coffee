Region = require '../../models/server/region'
Collection = require '../../models/collection'
_ = require 'underscore'

module.exports = ->
    s = @

    handoff = (server, options) ->
        # TODO: maybe we shouldn't be transporting the whole player object
        # TODO: class instances don't transport
        @emit 'leave'
        @message "§aLeaving server:#{s.id}"
        @_send 'handoff', server, @toJson(), options

    @regions = new Collection indexes: [{key: 'world.id', replace: true}, 'id']
    @regions.generateId = (region) -> "#{region.world.id}.#{region.regionId}"

    @master.on 'region', (r) =>
        region = @regions.get 'world.id', r.world.id

        if not region?
            region = new Region r
            @regions.insert region
            @info "starting region #{region.id}"
            @emit 'region', region
            region.start()

        else
            # TODO: hand off players to their new locations
            @info "remapping region #{region.id}"
            _.extend region, r
            region.updateChunkList()
            region.emit 'remap'

    @on 'join:before', (e, player) =>
        region = player.region = @regions.get 'world.id', player.storage.world
        region.players.insert player
        @debug "#{player.username} added to region:#{region.id}"

        player.handoff = handoff.bind player

        player.on 'moveChunk:after', (e, x, z) =>
            world = player.region.world

            if not world.map[x]?[z]?
                @debug "#{player.username}/#{player.id} moved to an unmapped chunk"

            else if world.map[x]?[z]?.region != player.region.regionId
                neighbor = world.servers[world.map[x][z].region]
                @debug "handing off #{player.username}/#{player.id} to server:#{neighbor.id} (region #{world.map[x][z].region})"
                player.handoff neighbor, {handoff: {transparent: true}, storage: player.storage}

        player.on 'toJson', (e, json) ->
            delete json.region

        player.on 'leave:after', (e) =>
            region = player.region
            region.players.remove player
            packet = entityIds: [player.entityId]
            region.send 0x1d, packet
            @debug "#{player.username} removed from region #{region.id}"

    @on 'update:before', (e, data) =>
        data.regions = []

        for region in @regions.models
            r =
                chunks: []
                players: region.players.length
                regionId: region.regionId
                worldId: region.world.id

            for chunk in region.chunkList
                r.chunks.push
                    x: chunk.x
                    z: chunk.z
                    players: region.players.grid[chunk.x]?[chunk.z]?.length or 0

            data.regions.push r
