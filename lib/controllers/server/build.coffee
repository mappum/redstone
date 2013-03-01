module.exports = ->
  @on 'join:after', (e, player) =>

    getCoordinates = (x, y, z, face) ->
      if face == 0 then y--
      else if face == 1 then y++
      else if face == 2 then z--
      else if face == 3 then z++
      else if face == 4 then x--
      else if face == 5 then x++
      return {x: x, y: y, z: z}

    player.on 0xe, (e, packet) =>
      # TODO: make sure player isn't cheating
      # TODO: support non-creative digging

      if packet.status == 0
        chunkX = Math.floor packet.x / 16
        chunkZ = Math.floor packet.z / 16

        player.region.chunks.getChunk chunkX, chunkZ, (err, chunk) =>
          return @error err if err
          chunk.setBlock 0,
            (packet.x + if packet.x < 0 then 1 else 0) % 16 + if packet.x < 0 then 15 else 0,
            packet.y,
            (packet.z + if packet.z < 0 then 1 else 0) % 16 + if packet.z < 0 then 15 else 0

          player.region.send player.position, 0x35,
            x: packet.x
            y: packet.y
            z: packet.z
            type: 0
            metadata: 0

    player.on 0xf, (e, packet) =>
      # TODO: make sure player isn't cheating
      coords = getCoordinates packet.x, packet.y, packet.z, packet.direction
      return if packet.heldItem.id < 0 or packet.heldItem.id > 255 or packet.direction < 0 or
        coords.y < 0 or coords.y > 255

      chunkX = Math.floor coords.x / 16
      chunkZ = Math.floor coords.z / 16

      player.region.chunks.getChunk chunkX, chunkZ, (err, chunk) =>
        return @error err if err
        chunk.setBlock packet.heldItem.id,
          (coords.x + if coords.x < 0 then 1 else 0) % 16 + if coords.x < 0 then 15 else 0,
          coords.y,
          (coords.z + if coords.z < 0 then 1 else 0) % 16 + if coords.z < 0 then 15 else 0

        player.region.send player.position, 0x35,
          x: coords.x
          y: coords.y
          z: coords.z
          type: packet.heldItem.id
          metadata: 0