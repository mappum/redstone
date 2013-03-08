ChunkCollection = require '../../models/server/chunkCollection'
superflatGenerator = require('../../generators/superflat')()
simpleStorage = require('../../storage/simple')

sendChunks = (player, chunks) =>
  # TODO: get view distance from settings
  viewDistance = 5

  # TODO: send in bulk packet rather than one by one
  for x in [-viewDistance+player.chunkX..viewDistance+player.chunkX]
    for z in [-viewDistance+player.chunkZ..viewDistance+player.chunkZ]
      do (x, z) =>
        if not player.loadedChunks["#{x}.#{z}"]
          chunks.getChunk x, z, (err, chunk) =>
            return @error err if err?
            chunk.toPacket {x: x, z: z}, (err, packet) =>
              return @error err if err?
              player.send 0x33, packet
              player.loadedChunks["#{x}.#{z}"] = true

module.exports = ->
  @on 'region:before', (e, region) =>
    region.chunks = new ChunkCollection
      generator: superflatGenerator
      storage: simpleStorage('data/chunks/'+region.id)

    # TODO: maybe we shouldn't always load all the chunks we are assigned?
    if region.area
      for chunk in region.area
        region.chunks.getChunk chunk.x, chunk.z

  @on 'join:before', (e, player) =>
    player.loadedChunks = {}
    sendChunks player, player.region.chunks

    player.on 'moveChunk:after', ->
      # TODO: mark chunks as out of range
      sendChunks player, player.region.chunks