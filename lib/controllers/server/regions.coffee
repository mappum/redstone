Region = require '../../models/server/region'
Collection = require '../../models/collection'

module.exports = ->
    @regions = new Collection indexes: ['id', 'world.id']
    @regions.generateId = (region) -> "#{region.world.id}.#{region.regionId}"

    @master.on 'region', (region) =>
        region = new Region region
        @regions.insert region
        @emit 'region', region
        region.start()
        @info "starting region #{region.id}"

    @on 'join:before', (e, player) =>
        region = player.region = @regions.get 'world.id', player.storage.world
        region.players.insert player
        @debug "#{player.username} added to region:#{region.id}"

    @on 'quit:after', (e, player) =>
        region = player.region
        region.players.remove player
        packet = entityIds: [player.entityId]
        region.send 0x1d, packet
        @debug "#{player.username} removed from region #{region.id}"
