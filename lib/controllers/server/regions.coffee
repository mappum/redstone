Region = require '../../models/server/region'
Collection = require '../../models/collection'

handoff = (server, options) ->
  @emit 'leave'
  @_send 'handoff', server, options

module.exports = ->
    @regions = new Collection indexes: [{key: 'world.id', replace: true}, 'id']
    @regions.generateId = (region) -> "#{region.world.id}.#{region.regionId}"

    @master.on 'region', (region) =>
        previous = @regions.get 'world.id', region.world.id
        region = new Region region
        @regions.insert region

        if previous?
            # TODO: hand off players to their new locations
            previous.stop()
            @info "reassigning from #{previous.id} to region #{region.id}"
        else
            @info "starting region #{region.id}"

        @emit 'region', region, previous
        region.start()

    @on 'join:before', (e, player) =>
        region = player.region = @regions.get 'world.id', player.storage.world
        region.players.insert player
        @debug "#{player.username} added to region:#{region.id}"

        player.handoff = handoff.bind player

        player.on 'command.s', -> @handoff player.region.world.servers[1], handoff: true

    @on 'quit:after', (e, player) =>
        region = player.region
        region.players.remove player
        packet = entityIds: [player.entityId]
        region.send 0x1d, packet
        @debug "#{player.username} removed from region #{region.id}"
