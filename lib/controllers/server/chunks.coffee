ChunkCollection = require '../../models/server/chunkCollection'

module.exports = (config) ->
  sendChunk = (player, x, z) ->
    player.region.chunks.getChunk x, z, (err, chunk) =>
      return @error err if err?
      chunk.toPacket {x: x, z: z}, (err, packet) =>
        return @error err if err?
        player.send 0x33, packet
        player.loadedChunks["#{x}.#{z}"] = true

  sendChunks = (player) ->
    viewDistance = config.viewDistance or 10

    # TODO: send in bulk packet rather than one by one
    for x in [-viewDistance+player.chunkX..viewDistance+player.chunkX]
      for z in [-viewDistance+player.chunkZ..viewDistance+player.chunkZ]
          d = Math.sqrt Math.pow(x - player.chunkX, 2) + Math.pow(z - player.chunkZ, 2)

          if d < viewDistance and not player.loadedChunks["#{x}.#{z}"]
            mappedChunk = player.region.world.map[x]?[z]?

            if not (player.region.world.static and not mappedChunk)
              sendChunk player, x, z
              player.region.chunkList.push {x: x, z: z} if not mappedChunk

  @on 'region:before', (e, region) =>
    options = {}

    if not region.static
      generator = require '../../generators/' + (region.world.generator?.type or 'superflat')
      options.generator = generator region.world.generator?.options

    if region.world.persistent
      storage = require '../../storage/' + (region.world.storage?.type or 'simple')
      options.storage = storage region.world.storage?.options or {path: "data/chunks/#{region.world.id}"}

    region.chunks = new ChunkCollection options

    # TODO: maybe we shouldn't always load all the chunks we are assigned?
    if region.assignment?
      region.chunks.getChunk chunk.x, chunk.z for chunk in region.assignment

  @on 'join:before', (e, player) =>
    player.loadedChunks = {}
    sendChunks player

    player.on 'moveChunk:after', ->
      # TODO: mark chunks as out of range
      sendChunks player