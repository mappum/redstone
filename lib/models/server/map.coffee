Model = require '../model'

MAP_SIZE = 128
HEADER_LENGTH = 3
COL_LENGTH = MAP_SIZE+HEADER_LENGTH

class Map extends Model
  constructor: (id) ->
    @id = id or 0
    @cols = []
    @buf = new Buffer COL_LENGTH * MAP_SIZE
    @buf.fill 0

    for x in [0...MAP_SIZE]
      buf = @buf.slice x * COL_LENGTH, (x+1) * COL_LENGTH
      buf[1] = x
      @cols[x] =
        buf: buf
        dStart: 0
        dEnd: MAP_SIZE-1

  getPixel: (x, y) ->
    @cols[x].buf[y+HEADER_LENGTH]

  setPixel: (value, x, y) ->
    @cols[x].buf[y+HEADER_LENGTH] = value

  sendTo: (player) ->
    packet =
      type: 358
      itemId: @id

    for col in @cols
      packet.text = col.buf.toString 'ascii'
      player.send 0x83, packet


module.exports = Map