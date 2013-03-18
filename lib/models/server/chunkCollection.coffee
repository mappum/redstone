Model = require '../model'
Chunk = require './chunk'

class ChunkCollection extends Model
  constructor: (options) ->
    @storage = options?.storage
    @generator = options?.generator

    @chunks = {}

  getChunk: (x, z, cb) ->
    cb = cb or ->
    col = @chunks[x]
    col = @chunks[x] = {} if not col?
    chunk = col[z]

    if not chunk
      chunk = col[z] = new Chunk

      generate = => @generateChunk x, z, cb

      if @storage? then @loadChunk x, z, (err, chunk) ->
        if err? or chunk? then cb err, chunk
        else generate()
      else generate()
    else
      cb null, chunk

  setChunk: (chunk, x, z) ->
    col = @chunks[x]
    col = @chunks[x] = {} if not col?
    col[z] = chunk

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

  unloadChunk: (x, z) -> @setChunk null, x, z

module.exports = ChunkCollection