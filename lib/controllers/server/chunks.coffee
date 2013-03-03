ChunkCollection = require '../../models/server/chunkCollection'
superflatGenerator = require('../../generators/superflat')()
simpleStorage = require('../../storage/simple')

sendChunks = (player, chunks) =>
  # TODO: get view distance from settings
  viewDistance = 5
  playerX = Math.floor player.position.x / 16
  playerZ = Math.floor player.position.z / 16

  # TODO: send in bulk packet rather than one by one
  for x in [-viewDistance+playerX..viewDistance+playerX]
    for z in [-viewDistance+playerZ..viewDistance+playerZ]
      ((x, z) =>
        if not player.loadedChunks["#{x}.#{z}"]
          chunks.getChunk x, z, (err, chunk) =>
            return @error err if err?
            chunk.toPacket {x: x, z: z}, (err, packet) =>
              return @error err if err?
              player.send 0x33, packet
              player.loadedChunks["#{x}.#{z}"] = true
      )(x, z)

module.exports = ->
  @on 'region:before', (e, region) =>
    region.chunks = new ChunkCollection
      generator: superflatGenerator
      storage: simpleStorage('data/chunks/'+region.id)

    # TODO: figure out which initial chunks to load
    for x in [-1..1]
      for z in [-1..1]
        region.chunks.getChunk x, z

  @on 'join:after', (e, player) =>
    player.loadedChunks = {}
    sendChunks player, player.region.chunks

    player.on 'moveChunk:after', ->
      # TODO: mark chunks as out of range
      sendChunks player, player.region.chunks