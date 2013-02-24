Collection = require '../../models/collection'
Region = require '../../models/master/region'

module.exports = ->
  @regions = new Collection

  # TODO: get rid of region queue
  @regionQueue = []
  @regions.on 'insert', (e, region) => @regionQueue.push region

  # TODO: load persistent regions from db
  @regions.insert new Region
    id: 'main'
    type: 'flat'
  @regions.insert new Region
    id: 'main2'
    type: 'flat'

  # TODO: spawn servers to hold regions

  @on 'peer.server', (e, server, connection) =>
    # TODO: rethink server region apportionment
    region = @regionQueue.shift()
    if region?
      @info "assigning region:#{region.id} to server:#{server.id}"
      connection.emit 'region', region
      region.server = server
      server.regions.push region

    connection.respond 'newRegion', (res, region) =>
      @regions.push region
      # TODO: spawn server (or select existing server) and tell it about new region
      # TODO: respond info about new region