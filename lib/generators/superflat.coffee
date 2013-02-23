module.exports = (options) ->
  blocks = options?.blocks or [
    {type: 7, height: 1}
    {type: 3, height: 2}
    {type: 2, height: 1}
  ]

  (chunk, chunkX, chunkZ) ->
    y = 1
    for block, i in blocks
      for j in [0...block.height]
        for x in [0...16]
          for z in [0...16]
            chunk.setBlock block.type, x, y, z
            chunk.setField 'skylight', 15, x-1, y+1, z if i == blocks.length-1 and j == block.height-1

        y++