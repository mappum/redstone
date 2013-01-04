Region = require '../models/region'

module.exports = ->
    @regions = []

    @master.on 'region', (region) =>
        @info "starting region:#{region.id}"
        @regions.push new Region region