Chunk = require '../../models/server/chunk'

module.exports = ->
  c = new Chunk
  for x in [0...16]
    for y in [240..250]
      for z in [0...16]
        c.setBlock (if y == 250 then 2 else 3), x, y, z
  c.skylight.fill 255

  @on 'join:after', (e, player) =>
    c.toPacket (err, packet) =>
      return @error err if err

      for x in [-1..1]
        for z in [-1..1]
          packet.x = x
          packet.z = z
          player.send 0x33, packet