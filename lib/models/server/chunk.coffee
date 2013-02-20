Model = require '../model'

getNibble = (buf, offset) ->
  offset /= 2
  word = buf[Math.floor offset]
  return if offset % 0 then word & 0xf else (word & 0xf0) >> 4

setNibble = (buf, value, offset) ->
  offset /= 2
  value &= 0xf
  i = Math.floor offset
  word = buf[i]
  if offset % 0
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
  constructor: ->
    @buf = new Buffer size
    @buf.fill 0
    offset = 0
    @[k] = @buf.slice offset, offset += v for k, v of sizes

  getBlock: (x, y, z) ->
    offset = @getOffset x, y, z
    return @types[offset]

  setBlock: (value, x, y, z) ->
    offset = @getOffset x, y, z
    @types[offset] = value

  getField: (field, x, y, z) -> getNibble @[field], @getOffset(x, y, z)

  setField: (field, value, x, y, z) -> setNibble @[field], value, @getOffset(x, y, z)

  getOffset: (x, y, z) ->
    subchunk = @getSubChunk y
    offset = subchunk * 16 * 16 * 16
    offset += x * 16 * 16 + y % 16 + z * 16
    return offset

  getSubChunk: (y) ->
    return Math.floor y / 16

module.exports = Chunk