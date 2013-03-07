Collection = require '../../models/collection'
Region = require '../../models/master/region'
_ = require 'underscore'

module.exports = (config) ->  
  @on 'db.ready:after', (e) =>
    @regions = new Collection

    @remapRegions = =>
      # TODO: handle more than one region
      #for region in @regions.models
      region = @regions.get 0
      region.remap areas: @peers.servers.length

      servers = []
      for server in @peers.servers.models
        servers.push _.pick server, 'id', 'interfaceType', 'interfaceId'

      for area, i in region.areas
        server = @peers.servers.get i
        @info "assigning region:#{region.id} area:#{i} to server:#{server.id}"
        server.connection.emit 'region',
          id: region.id
          type: region.type
          chunks: area
          area: i
          map: region.map
          servers: servers

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