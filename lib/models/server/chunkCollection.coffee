Model = require '../model'
Chunk = require './chunk'
async = require 'async'
_ = require 'underscore'
zlib = require 'zlib'

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
    chunk.timeLoaded = Date.now() if chunk?

  generateChunk: (x, z, cb) ->
    cb = cb or ->
    chunk = new Chunk
    if typeof @generator == 'function' then @generator chunk, x, z
    else if @generator instanceof Array
      generator chunk, x, z for generator in @generator
    @setChunk chunk, x, z
    cb null, chunk

  loadChunk: (x, z, cb) ->
    @storage.get x, z, (err, chunk) =>
      return cb err if err?
      @setChunk chunk, x, z
      cb null, chunk

  storeChunk: (x, z, cb) ->
    cb = cb or ->
    @getChunk x, z, (err, chunk) =>
      return cb err if err?
      @storage.set chunk, x, z, cb

  unloadChunk: (x, z) -> @setChunk null, x, z

  toPacket: (chunks, cb) ->
    tasks = []
    for chunk in chunks
      do (chunk) =>
        tasks.push (cb) =>
          @getChunk chunk.x, chunk.z, (err, c) ->
            c.toPacket {x: chunk.x, z: chunk.z, compress: false}, cb

    async.parallel tasks, (err, results) ->
      return cb err if err?

      meta = []
      buffers = []
      length = 0

      for chunk in results
        meta.push _.omit chunk, 'groundUp', 'data'
        buffers.push chunk.data
        length += chunk.data.length

      data = Buffer.concat buffers, length

      zlib.deflate data, (err, compressed) ->
        return cb err if err?

        cb null,
          meta: meta
          compressedChunkData: compressed
          skyLightSent: true


module.exports = ChunkCollection