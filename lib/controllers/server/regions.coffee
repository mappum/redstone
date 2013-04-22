Region = require '../../models/server/region'
Collection = require '../../models/collection'
GridCollection = require '../../models/gridCollection'
_ = require 'underscore'

module.exports = ->
  s = @

  handoff = (server, options) ->
    @emit 'leave'
    @message "§aLeaving server:#{s.id}"
    @_send 'handoff', server, @toJson(), options

  @regions = new Collection indexes: [{key: 'world.id', replace: true}, 'id']
  @regions.generateId = (region) -> "#{region.world.id}.#{region.regionId}"

  @master.on 'region', (r, options) =>
    region = @regions.get 'world.id', r.world.id
    options = options or {}

    r.world.map = new GridCollection r.world.map

    delay = options.delay = options.start - Date.now() if options.start?

    if not region?
      region = new Region r
      @regions.insert region
      @info "starting region #{region.id}"
      @emit 'region', region, options
      region.start()

    else
      # calculate diff of chunks inside region
      options.chunks =
        add: []
        remove: []
        keep: []

      chunkGrid = new GridCollection

      for chunk in region.chunkList
        chunkGrid.set chunk, chunk.x, chunk.z
        newRegion = r.world.map.get(chunk.x, chunk.z)?.region
        if newRegion != r.regionId
          chunk.region = newRegion
          options.chunks.remove.push chunk
        else
          options.chunks.keep.push chunk
      for chunk in r.assignment
        options.chunks.add.push chunk if not chunkGrid.get(chunk.x, chunk.z)?

      # do stuff that needs to happen before actual remap (e.g. saving/loading)
      @info "preparing to remap region #{region.id}"
      region.emit 'preRemap', r, options

      # make the remap active
      remap = =>
        @info "remapping region #{region.id}"
        _.extend region, r

        # in chunks that we aren't handling anymore,
        # handoff the players to their new server
        for chunk in options.chunks.remove
          if chunk.players
            newServer = region.world.servers[chunk.region]
            players = region.players.grid[chunk.x][chunk.z].models

            for player in players
              if player?
                player.handoff newServer,
                  handoff: transparent: true
                  storage: player.storage

        # recalculate who our neighbors are and reset some stuff
        region.update()
        
        # connect to new neighbors
        # TODO: disconnect from neighbors when not needed
        @connect neighbor for neighbor in region.neighbors

        region.emit 'remap'

      setTimeout remap, delay

  @on 'join:before', (e, player) =>
    region = player.region = @regions.get 'world.id', player.storage.world
    region.players.insert player
    @debug "#{player.username} added to region:#{region.id}"

    player.handoff = handoff.bind player

    player.on 'moveChunk:after', (e, x, z) =>
      world = player.region.world
      chunk = world.map.get x, z

      if not chunk?
        @debug "#{player.username}/#{player.id} moved to an unmapped chunk"

      else if chunk.region != player.region.regionId
        neighbor = world.servers[chunk.region]
        @debug "handing off #{player.username}/#{player.id} to server:#{neighbor.id} (region #{chunk.region})"
        player.handoff neighbor, {handoff: {transparent: true}, storage: player.storage}

    player.on 'toJson', (e, json) ->
      delete json.region

    player.on 'leave:after', (e) =>
      region = player.region
      region.players.remove player
      packet = entityIds: [player.entityId]
      region.send 0x1d, packet
      @debug "#{player.username} removed from region #{region.id}"

  @on 'update:before', (e, data) =>
    data.regions = []

    for region in @regions.models
      r =
        chunks: {}
        players: region.players.length
        regionId: region.regionId
        worldId: region.world.id

      for chunk in region.chunkList
        players = region.players.grid[chunk.x]?[chunk.z]?.length or 0
        if not chunk.players? or players != chunk.players
          obj = {}
          obj.players = players if players or chunk.players?
          
          col = r.chunks[chunk.x]
          col = r.chunks[chunk.x] = {} if not col?

          col[chunk.z] = obj                    
          chunk.players = players

      data.regions.push r
