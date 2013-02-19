Region = require '../../models/server/region'

module.exports = ->
    @regions = []
    @regions.ids = {}

    @master.on 'region', (region) =>
        region = new Region region

        @regions.push region
        @regions.ids[region.id] = region

        @info "starting region:#{region.id}"

        @emit 'region', region
        region.start()

    @on 'join:before', (e, player) =>
        region = player.region = @regions.ids[player.storage.region]

        region.players.insert player

        @debug "#{player.username} added to region:#{region.id}"

    @on 'quit:before', (e, player) =>
        region = player.region
        region.players.remove player

        packet = entityIds: [player.entityId]
        for p in region.players
            p.send 0x1d, packet

        @debug "#{player.username} removed from region:#{region.id}"
