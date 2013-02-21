ChunkCollection = require '../../models/server/chunkCollection'
SuperflatGenerator = require '../../generators/superflat'

module.exports = ->
  chunks = @chunks = new ChunkCollection {generator: SuperflatGenerator}

  for x in [-1..1]
    for z in [-1..1]
      @chunks.getChunk x, z

  sendChunks = (player) ->
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

  @on 'join:after', (e, player) =>
    player.loadedChunks = {}
    sendChunks player

    player.on 'moving:after', ->
      # TODO: mark chunks as out of range
      sendChunks player