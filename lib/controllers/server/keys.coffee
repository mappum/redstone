MARGIN = 35

module.exports = ->
  @on 'join:after', (e, player) =>
    wasPressed = {}

    player.on 'move:after', (e, d) =>
      facing = player.position.yaw % 360
      facing += 360 if facing < 0

      moving = Math.atan2 d.z, d.x
      moving *= 180 / Math.PI
      moving -= 90
      moving += 360 if moving < 0

      diff = facing - moving
      diff += 360 if diff < 0

      pressed =
        w: diff > 270 + MARGIN or diff < 90 - MARGIN
        s: 90 + MARGIN < diff < 270 - MARGIN
        a: MARGIN < diff < 180 - MARGIN
        d: 180 + MARGIN < diff < 360 - MARGIN

      for key, v of pressed
        if v
          player.emit 'key.'+key if not wasPressed[key]
          wasPressed[key] = true
        else wasPressed[key] = false