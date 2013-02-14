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

        region.players.push player
        region.players.usernames[player.username] = player

        @debug "#{player.username} added to region:#{region.id}"

    @on 'quit:before', (e, player) =>
        region = player.region

        region.players.splice region.players.indexOf(player), 1
        region.players.usernames[player.username] = undefined

        packet = entityIds: [player.entityId]
        for p in region.players
            p.send 0x1d, packet

        @debug "#{player.username} removed from region:#{region.id}"
