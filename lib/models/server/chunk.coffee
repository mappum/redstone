module.exports = class Chunk

	constructor: ()->
		@types = new Buffer 16 * 256 * 16

	getBlock: (x, y, z)=>
		offset = @getOffset(x, y, z)
		return @types[offset]

	setBlock: (value, x, y, z) =>
		offset = @getOffset(x, y, z)
		@types[offset] = value
	getOffset: (x, y, z)=>
		subchunk = @getSubChunk(y)
		offset = subchunk * 16 * 16 * 16
		offset += x * 16 * 16 + y % 16 + z * 16
		return offset
	getSubChunk: (y)=>
		return Math.floor y / 16

test = ()->
	assert = require 'assert'
	chunk = new Chunk()
	assert(chunk.getSubChunk(253) is 15, "Y coordinate 253 is in the top subchunk")
	assert(chunk.getOffset(0, 0, 0) is 0, "Offset of 0, 0, 0 is 0") 
	assert(chunk.getOffset(15, 255, 15) is 65535, "15, 255, 15 is the last element of the chunk buffer")
	assert(chunk.getBlock(13, 33, 37) is 0, "Block at 13, 33, 37 is 0")
	chunk.setBlock(1, 13, 33, 37) # change block to stone from air
	assert(chunk.getBlock(13, 33, 37) is 1, "Block is now 1")

	console.log "All tests passed!"
test()