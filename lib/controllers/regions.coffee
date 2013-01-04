Region = require '../models/region'

module.exports = ->
    @regions = []
    @regions.ids = {}

    @master.on 'region', (region) =>
        region = new Region region

        @regions.push region
        @regions.ids[region.id] = region

        @info "starting region:#{region.id}"
        @emit 'region', region

    @on 'join:before', (e, player, state) =>
        region = @regions.ids[state.regionId]

        region.players.push player
        region.players.usernames[player.username] = player

        player.region = region

        @debug "#{player.username} added to region:#{region.id}"