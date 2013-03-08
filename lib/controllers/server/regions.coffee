Region = require '../../models/server/region'
Collection = require '../../models/collection'

module.exports = ->
    @regions = new Collection

    @master.on 'region', (region) =>
        region = new Region region
        @regions.insert region
        @emit 'region', region
        region.start()
        @info "starting region:#{region.id} area:#{region.areaId}"

    @on 'join:before', (e, player) =>
        region = player.region = @regions.get player.storage.region
        region.players.insert player
        @debug "#{player.username} added to region:#{region.id}"

    @on 'quit:after', (e, player) =>
        region = player.region
        region.players.remove player
        packet = entityIds: [player.entityId]
        region.send 0x1d, packet
        @debug "#{player.username} removed from region:#{region.id}"
