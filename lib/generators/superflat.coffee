module.exports = (options) ->
  blocks = options?.blocks or [
    {type: 7, height: 1}
    {type: 3, height: 2}
    {type: 2, height: 1}
  ]

  (chunk, chunkX, chunkZ) ->
    y = 0
    for block, i in blocks
      for j in [0...block.height]
        for x in [0...16]
          for z in [0...16]
            chunk.setBlock block.type, x, y, z
        y++

    # TODO: do real lighting instead of just lighting everything
    chunk.skylight.fill 0xf