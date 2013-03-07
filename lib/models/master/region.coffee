Model = require '../model'
Collection = require '../collection'
_ = require 'underscore'

class Region extends Model
  constructor: (options) ->
    _.extend @, options
    @generateMap()

  # creates an empty map of chunks that will be mapped to servers (used when starting up a region)
  generateMap: ->
    @map = {}

    # if we already know what chunks exist, map those
    if @chunks
      chunks = @chunks

    # if we have a specified size, map that area
    else if @size?
      chunks = []
      for x in [Math.floor(-@size.width/2)+1..Math.floor(@size.width/2)]
        for y in [Math.floor(-@size.height/2)+1..Math.floor(@size.height/2)]
          chunks.push {x: x, y: y}

    # if this is a new region, map the spawn area
    else
      # TODO: use settings for spawn size / location
      chunks = [{x: 0, y: 0}]

    for chunk in chunks
      col = @map[chunk.x]
      col = @map[chunk.x] = {} if not col?
      mapChunk = col[chunk.y] = population: 0

    @map.length = chunks.length

  # maps chunks into areas based on population
  remap: (options) ->
    # TODO: refactor to minimize moving areas to new servers
    # TODO: use historical population statistics to guess best mapping
    # TODO: make less shitty
    areaN = options?.areas or 1
    @areas = []
    remaining = @map.length

    setChunk = (x, z, area) =>
      chunk = @map[x][z]
      chunk.area = area
      @areas[area] = @areas[area] or []
      @areas[area].push chunk
      remaining--

    chunks = []
    for x, col of @map
      for z, chunk of col
        chunks.push {x: +x, z: +z, chunk: @map[x][z]}

    chunks.sort (a, b) ->
      diff = a.chunk.population - b.chunk.population
      if diff > 0 then return -1
      else if diff < 0 then return 1
      else return 0

    centers = chunks.slice 0, areaN
    chunk.area = area for chunk, area in centers

    for chunk in chunks
      closestD = null
      for center in centers
        d = Math.sqrt Math.pow(chunk.x - center.x, 2) + Math.pow(chunk.z - center.z, 2)
        if not closestD? or d < closestD
          closestD = d
          closestCenter = center
      setChunk chunk.x, chunk.z, closestCenter.area

    # TODO: balance areas

module.exports = Region