module.exports = (chunk, chunkX, chunkZ) ->
  chunk.skylight.fill 255
  for x in [0...16]
    for y in [60..64]
      for z in [0...16]
        chunk.setBlock (if y == 64 then 2 else 3), x, y, z