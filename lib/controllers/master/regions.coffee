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

      # region options:
      #   regionId: the id of this region (0-indexed)
      #   world: info about the world this region is a part of
      #   assignment: an array of the chunks in this region (in the format
      #               [{x: x, z: z}, ...])
      #   static: if true, the server should not expand to unmapped chunks (it
      #           should only handle chunks it was assigned to)

      # world options
      #   id: the id of the world this region is in (a string)
      #   map: a map of the assigned chunks
      #   servers: an array of the servers hosting the regions in this world,
      #            ordered by the regionId they are assigned to
      #   persistent: whether or not this is a persistent world (and should
      #               be loaded from disk/saved to db/etc)
      #   meta: an object that contains the level type/dimension/etc. settings
      #   generator: an object that contains the chunk generator type and options to use
      #   storage: an object that contains the chunk storage type and options

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