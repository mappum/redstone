_ = require 'underscore'

module.exports = (config) ->  

  # assign servers to worlds, map chunks to them, then notify servers of mappings
  @remapRegions = =>
    # TODO: handle more than one world
    #for world in @worlds.models
    world = @worlds.get 0
    world.remap @peers.servers.length

    servers = []
    for server in @peers.servers.models
      servers.push _.pick server, 'id', 'interfaceType', 'interfaceId'

    for region, i in world.regions
      # TODO: figure out how servers should be assigned to worlds
      server = @peers.servers.get i
      @info "assigning region #{world.id}.#{i} to server:#{server.id}"
      server.connection.emit 'region',
        regionId: i
        world:
          # TODO: include world meta info (dimension, difficulty, etc)
          id: world.id
          map: world.map
          servers: servers
        assignment: region

  @on 'peer.server:after', (e, server, connection) =>
    @remapRegions()