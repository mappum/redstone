ChunkCollection = require '../../models/server/chunkCollection'
async = require 'async'

module.exports = (config) ->

  sendChunk = (x, z) ->
    @region.chunks.getChunk x, z, (err, chunk) =>
      return @error err if err?
      chunk.toPacket {x: x, z: z}, (err, packet) =>
        return @error err if err?
        @send 0x33, packet

  sendChunks = ->
    initial = not @settings?

    maxViewDistance = config.viewDistance or 9
    multiplier = (5 - if not initial then @settings.viewDistance else 3) / 5
    viewDistance = Math.round multiplier * maxViewDistance

    chunkRate =
      if initial then 0
      else if config.chunkInterval? then config.chunkInterval
      else 10

    tasks = []
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
            @region.chunkList.push {x: x, z: z} if not mappedChunk
            do (x, z, chunk) =>
              tasks.push (cb) =>
                @sendChunk x, z

                col = @loadedChunks[x]
                col = @loadedChunks[x] = {} if not col?
                col[z] = chunk.lastUpdate

                done = -> cb null, true
                if chunkRate then setTimeout done, chunkRate
                else done()

    async.series tasks

  saveChunks = ->
    for chunk in @chunkList
      do (chunk) =>
        @chunks.getChunk chunk.x, chunk.z, (err, c) =>
          if not c.lastSave? or c.lastUpdate > c.lastSave
            @chunks.storeChunk chunk.x, chunk.z

  @on 'region:before', (e, region, options) =>
    collectionOptions = {}

    if not region.static
      generator = require '../../generators/' + (region.world.generator?.type or 'superflat')
      collectionOptions.generator = generator region.world.generator?.options

    if region.world.persistent
      storage = require '../../storage/' + (region.world.storage?.type or 'simple')
      collectionOptions.storage = storage region.world.storage?.options or {path: "data/chunks/#{region.world.id}"}

    region.chunks = new ChunkCollection collectionOptions

    getChunks = ->
      # TODO: maybe we shouldn't always load all the chunks we are assigned?
      region.chunks.getChunk chunk.x, chunk.z for chunk in region.assignment
    if options.delay then setTimeout getChunks, options.delay / 2
    else getChunks()

    region.saveChunks = saveChunks.bind region
    region.saveTimer = setInterval region.saveChunks, config.saveInterval or 60 * 1000

    region.on 'preRemap:before', (e, r, options) ->
      loadChunks = ->
        region.chunks.loadChunk chunk.x, chunk.z for chunk in options.chunks.add
      setTimeout loadChunks, options.delay / 2

      region.chunks.storeChunk chunk.x, chunk.z for chunk in options.chunks.remove

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

  @on 'update:after', (e, data, lastUpdate) =>
    for region, i in @regions.models
      r = data.regions[i]
      for chunk in region.chunkList
        do (chunk) =>
          region.chunks.getChunk chunk.x, chunk.z, (err, c) =>
            return @error err if err?
            if c.lastUpdate >= lastUpdate
              col = r.chunks[chunk.x]
              col = r.chunks[chunk.x] = {} if not col?
              updateChunk = col[chunk.z]
              updateChunk = col[chunk.z] = {} if not updateChunk?
              updateChunk.lastUpdate = c.lastUpdate