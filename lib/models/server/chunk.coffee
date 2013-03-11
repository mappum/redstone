Model = require '../model'
zlib = require 'zlib'

getNibble = (buf, offset) ->
  offset /= 2
  word = buf[Math.floor offset]
  return if offset % 0 then word & 0xf else (word & 0xf0) >> 4

setNibble = (buf, value, offset) ->
  value &= 0xf
  i = Math.floor offset / 2
  word = buf[i]
  if offset % 2 == 1
    word = (word | 0xf) ^ 0xf
    word |= value
  else
    word = (word | 0xf0) ^ 0xf0
    word |= value << 4
  buf[i] = word

sizes =
  types: 16 * 256 * 16
  meta: 16 * 256 * 16 / 2
  light: 16 * 256 * 16 / 2
  skylight: 16 * 256 * 16 / 2
  add: 16 * 256 * 16 / 2
  biomes: 16 * 16

size = 0
size += v for k, v of sizes

class Chunk extends Model
  constructor: (@buf) ->
    if not @buf?
      @buf = new Buffer size
      @buf.fill 0
    offset = 0
    @[k] = @buf.slice offset, offset += v for k, v of sizes
    @lastUpdate = null

  getBlock: (x, y, z) ->
    # TODO: set add values
    @types[@getOffset x, y, z]

  setBlock: (value, x, y, z) ->
    # TODO: get add values
    @types[@getOffset x, y, z] = value
    @lastUpdate = Date.now()

  getField: (field, x, y, z) ->
    getNibble @[field], @getOffset(x+1, y, z)

  setField: (field, value, x, y, z) ->
    setNibble @[field], value, @getOffset(x+1, y, z)
    @lastUpdate = Date.now()

  getOffset: (x, y, z) -> y * 16 * 16 + z * 16 + x % 16

  toPacket: (options, cb) ->
    if typeof options == 'function'
      cb = options
      options = null

    options = options or {}
    x = options.x or 0
    z = options.z or 0
    compress = if options.compress? then options.compress else true

    # TODO: don't always send the whole thing
    output =
      x: x
      z: z
      groundUp: true
      bitMap: 0xffff
      addBitMap: 0

    if compress
      zlib.deflate @buf, (err, data) ->
        return cb err if err
        output.compressedChunkData = data
        cb null, output
    else
      output.data = @buf
      cb null, output

module.exports = Chunk