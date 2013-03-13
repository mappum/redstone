ChunkCollection = require '../../models/server/chunkCollection'

module.exports = (config) ->
  sendChunks = (player) ->
    viewDistance = config.chunks?.viewDistance or 9
    chunksPerPacket = config.chunks?.perPacket or 200

    chunks = []

    for x in [-viewDistance+player.chunkX..viewDistance+player.chunkX]
      for z in [-viewDistance+player.chunkZ..viewDistance+player.chunkZ]

          d = Math.sqrt Math.pow(x - player.chunkX, 2) + Math.pow(z - player.chunkZ, 2)

          lastUpdate = player.loadedChunks[x]?[z]
          chunk = player.region.chunks.chunks[x]?[z]? and player.region.chunks.chunks[x][z]
          mappedChunk = player.region.world.map[x]?[z]?
          localChunk = mappedChunk and player.region.world.map[x][z].region == player.region.regionId

          old = lastUpdate != true and (not lastUpdate or lastUpdate < if localChunk then chunk.lastUpdate else chunk.timeLoaded)
          oob = player.region.world.static and not mappedChunk

          if d < viewDistance and old and not oob
            chunks.push {x: x, z: z}
            player.region.chunkList.push {x: x, z: z} if not mappedChunk

            col = player.loadedChunks[x]
            col = player.loadedChunks[x] = {} if not col?
            if localChunk then col[z] = true
            else col[z] = chunk.timeLoaded

    i = 0
    while i < chunks.length
      subChunks = chunks.slice i, i + chunksPerPacket
      player.region.chunks.toPacket chunks, (err, packet) ->
        return @error err if err?
        player.send 0x38, {data: packet}
      i += chunksPerPacket

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

  @on 'join:before', (e, player, options) =>
    player.loadedChunks = {} if not options.handoff?.transparent
    
    sendChunks player

    player.on 'moveChunk:after', ->
      sendChunks player

    player.on 'leave:before', ->
      now = Date.now()
      for chunk in player.region.chunkList
        col = player.loadedChunks[chunk.x]
        col = player.loadedChunks[chunk.x] = {} if not col?
        col[chunk.z] = now