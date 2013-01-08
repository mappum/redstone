Region = require '../models/region'

module.exports = ->
    @regions = []
    @regions.ids = {}

    @master.on 'regions', (regions) =>
        console.log regions

    @master.on 'region', (region) =>
        region = new Region region

        @regions.push region
        @regions.ids[region.id] = region

        @emit 'region', region

    @on 'join:before', (e, player) =>
        region = @regions.ids[player.regionId]

        region.players.push player
        region.players.usernames[player.username] = player

        player.region = region

        @debug "#{player.username} added to region:#{region.id}"

    @on 'command.s', (e, player) =>
        console.log "/s from #{player.username}"