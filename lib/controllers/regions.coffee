Region = require '../models/region'

module.exports = ->
    @regions = []
    @regions.ids = {}

    @master.on 'neighbors', (@neighbors) =>

    @master.on 'region', (region) =>
        region = new Region region

        @regions.push region
        @regions.ids[region.id] = region

        @info "starting region:#{region.id}"

        @emit 'region', region
        region.start()

    @on 'join:before', (e, player) =>
        region = @regions.ids[player.state.regionId]

        region.players.push player
        region.players.usernames[player.username] = player

        player.region = region

        @debug "#{player.username} added to region:#{region.id}"

    @on 'quit:before', (e, player) =>
        region = @regions.ids[player.state.regionId]

        region.players.splice region.players.indexOf(player), 1
        region.players.usernames[player.username] = undefined

        @debug "#{player.username} removed from region:#{region.id}"

    @on 'command.s', (e, player) =>
        console.log "/s from #{player.username}"
        console.log @neighbors