Model = require '../model'

class Chunk extends Model
	constructor: ->
		@types = new Buffer 16 * 256 * 16

	getBlock: (x, y, z) ->
		offset = @getOffset x, y, z
		return @types[offset]

	setBlock: (value, x, y, z) ->
		offset = @getOffset x, y, z
		@types[offset] = value

	getOffset: (x, y, z) ->
		subchunk = @getSubChunk y
		offset = subchunk * 16 * 16 * 16
		offset += x * 16 * 16 + y % 16 + z * 16
		return offset

	getSubChunk: (y) ->
		return Math.floor y / 16

module.exports = Chunk