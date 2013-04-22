_ = require 'underscore'

module.exports = (config) ->  
  # assign servers to worlds, map chunks to them, then notify servers of mappings
  @mapRegions = =>
    # TODO: handle more than one world
    #for world in @worlds.models
    world = @worlds.get 0
    world.remap @peers.servers.length

    world.servers = []
    for server in @peers.servers.models
      world.servers.push _.pick server, 'id', 'interfaceType', 'interfaceId'

    options = {}
    remapDelay = if config.remapDelay? then config.remapDelay else 10 * 1000
    options.start = Date.now() + remapDelay

    for region, i in world.regions
      # TODO: figure out how servers should be assigned to worlds
      server = @peers.servers.get i
      @info "assigning region #{world.id}.#{i} to server:#{server.id}"

      # region options:
      #   regionId: the id of this region (0-indexed)
      #   world: info about the world this region is a part of
      #   assignment: an array of the chunks in this region (in the format [{x: x, z: z}, ...])

      # world options
      #   id: the id of the world this region is in (a string)
      #   map: a GridCollection of the assigned chunks
      #   servers: an array of the servers hosting the regions in this world, ordered by the regionId they are assigned to
      #   persistent: whether or not this is a persistent world (and should be loaded from disk/saved to db/etc)
      #   meta: an object that contains the level type/dimension/etc. settings
      #   generator: an object that contains the chunk generator type and options to use
      #   storage: an object that contains the chunk storage type and options
      #   size: the size limit of the world, either a number, or an object like {width: x, height: x}
      #   pregen: whether or not to pregenerate all chunks (size must be defined)
      #   static: whether or not to expand to unmapped chunks (servers should only load assigned chunks)

      server.connection.emit 'region', {
        regionId: i
        world: world
        assignment: region
      }, options

  resetTimer = =>
    clearInterval @remapTimer if @remapTimer?
    @remapTimer = setInterval @mapRegions, config.remapInterval or 4 * 60 * 1000

  remapTimeout = null
  remap = =>
    @mapRegions()
    resetTimer()
    remapTimeout = null

  @on 'peer.server:after', (e, server, connection) =>
    remapTimeout = setTimeout remap, 2000 if not remapTimeout?
    connection.on 'disconnect', remap

  @on 'peer.server.update:after', (e, server, stats) =>
    for region in stats.regions
      world = @worlds.get region.worldId

      if world?
        for x, col of region.chunks
          for z, chunk of col
            c = world.getChunk(x, z)
            _.extend c, chunk
            c.players = c.players or 0