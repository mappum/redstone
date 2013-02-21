module.exports = (chunk, chunkX, chunkZ) ->
  for x in [0...16]
    for y in [60..64]
      for z in [0...16]
        chunk.setBlock (if y == 64 then 2 else 3), x, y, z
        if y == 64
          chunk.setField 'skylight', 15, x, y, z
          chunk.setField 'light', 15, x, y, z