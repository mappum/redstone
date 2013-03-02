Collection = require '../../models/collection'
Region = require '../../models/master/region'

module.exports = ->  
  @on 'db.ready:after', (e) =>
    @regions = new Collection

    @remapRegions = =>
      # TODO: actually split up regions and assign chunks to servers
      for region in @regions.models
        server = @peers.servers.get 0
        @info "assigning region:#{region.id} to server:#{server.id}"
        server.connection.emit 'region', region

    @db.ensureIndex 'regions', {id: 1}, ->

    @db.find 'regions', {}, (err, regions) =>
      return @error err if err
      @regions.insert new Region region for region in regions

    # TODO: spawn servers to hold regions

    @on 'peer.server:after', (e, server, connection) =>
      @remapRegions()

      connection.respond 'newRegion', (res, region) =>
        #@regions.insert region
        # TODO: spawn server (or select existing server) and tell it about new region
        # TODO: respond info about new region