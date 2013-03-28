Model = require '../model'
Collection = require '../collection'
_ = require 'underscore'

class World extends Model
  constructor: (options) ->
    _.extend @, options

    @map = {}
    @chunks = []

    # TODO: figure out which chunks to map initially
    for x in [-4..5]
      for z in [-4..5]
        @getChunk x, z

    @remap()

  # maps chunks into regions based on population
  remap: (regions, options) ->
    # TODO: refactor to minimize moving regions to new servers
    # TODO: use historical population statistics to guess best mapping
    # TODO: make less shitty after seeing player behavior (hire someone who is pro?)
    regions = regions or 1
    @regions = []

    @chunks.sort (a, b) ->
      Math.floor(Math.random() * 3) - 1

    @chunks.sort (a, b) ->
      diff = a.players - b.players
      if diff > 0 then return -1
      else if diff < 0 then return 1
      else return 0

    centers = @chunks.slice 0, regions
    chunk.region = region for chunk, region in centers

    for chunk in @chunks
      closestD = null
      for center in centers
        d = Math.sqrt Math.pow(chunk.x - center.x, 2) + Math.pow(chunk.z - center.z, 2)
        if not closestD? or d < closestD
          closestD = d
          closestCenter = center

      region = closestCenter.region
      chunk.region = region
      @regions[region] = @regions[region] or []
      @regions[region].push chunk

    # TODO: balance regions

  getChunk: (x, z) ->
    col = @map[x]
    col = @map[x] = {} if not col?
    chunk = col[z]
    if not chunk?
      chunk = col[z] = {x: x, z: z, players: 0}
      @chunks.push chunk
    chunk

module.exports = World