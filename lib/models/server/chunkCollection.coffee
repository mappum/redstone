Model = require '../model'
GridCollection = require '../gridCollection'
Chunk = require './chunk'

class ChunkCollection extends Model
  constructor: (options) ->
    @storage = options?.storage
    @generator = options?.generator

    @chunks = new GridCollection

  getChunk: (x, z, cb) ->
    cb = cb or ->
    chunk = @chunks.get x, z

    if not chunk
      chunk = new Chunk
      @chunks.set chunk, x, z

      generate = => @generateChunk x, z, cb

      if @storage? then @loadChunk x, z, (err, chunk) ->
        if err? or chunk? then cb err, chunk
        else generate()
      else generate()
    else
      cb null, chunk

  setChunk: (chunk, x, z) ->
    @chunks.set chunk, x, z

  generateChunk: (x, z, cb) ->
    cb = cb or ->
    chunk = new Chunk
    if typeof @generator == 'function' then @generator chunk, x, z
    else if @generator instanceof Array
      generator chunk, x, z for generator in @generator
    chunk.lastUpdate = Date.now()
    @setChunk chunk, x, z
    cb null, chunk

  loadChunk: (x, z, cb) ->
    cb = cb or ->
    @storage.get x, z, (err, chunk) =>
      return cb err if err?
      if chunk?
        chunk.lastUpdate = Date.now()
        @setChunk chunk, x, z
      cb null, chunk

  storeChunk: (x, z, cb) ->
    cb = cb or ->
    @getChunk x, z, (err, chunk) =>
      return cb err if err?
      chunk.lastSave = Date.now()
      @storage.set chunk, x, z, cb

  unloadChunk: (x, z) ->
    @chunks.remove x, z

module.exports = ChunkCollection