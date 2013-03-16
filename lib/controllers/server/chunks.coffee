ChunkCollection = require '../../models/server/chunkCollection'

module.exports = (config) ->

  sendChunk = (x, z) ->
    @region.chunks.getChunk x, z, (err, chunk) =>
      return @error err if err?
      chunk.toPacket {x: x, z: z}, (err, packet) =>
        return @error err if err?
        @send 0x33, packet

  sendChunks = ->
    maxViewDistance = config.viewDistance or 9
    multiplier = (5 - if @settings? then @settings.viewDistance else 3) / 5
    viewDistance = Math.round multiplier * maxViewDistance

    for x in [-viewDistance+@chunkX..viewDistance+@chunkX]
      for z in [-viewDistance+@chunkZ..viewDistance+@chunkZ]
        lastUpdate = @loadedChunks[x]?[z]
        chunk = @region.chunks.chunks[x]?[z]? and @region.chunks.chunks[x][z]
        mappedChunk = @region.world.map[x]?[z]?
        localChunk = mappedChunk and @region.world.map[x][z].region == @region.regionId

        old = lastUpdate != true and (not lastUpdate or lastUpdate < chunk.lastUpdate)
        oob = @region.world.static and not mappedChunk

        if old and not oob
          d = Math.sqrt Math.pow(x - @chunkX, 2) + Math.pow(z - @chunkZ, 2)
          if d < viewDistance
            @sendChunk x, z
            @region.chunkList.push {x: x, z: z} if not mappedChunk

            col = @loadedChunks[x]
            col = @loadedChunks[x] = {} if not col?
            col[z] = lastUpdate

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
    player.sendChunk = sendChunk.bind player
    player.sendChunks = sendChunks.bind player

  @on 'join:after', (e, player) ->
    player.sendChunks()
    player.on 'ready:after', player.sendChunks
    player.on 'moveChunk:after', player.sendChunks

    player.on 'leave:before', ->
      now = Date.now()
      for chunk in player.region.chunkList
        col = player.loadedChunks[chunk.x]
        col = player.loadedChunks[chunk.x] = {} if not col?
        col[chunk.z] = now