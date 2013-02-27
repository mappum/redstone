Map = require '../../models/server/map'
_ = require 'underscore'

LENGTH_INCREMENT = 10
SPEED_INCREMENT = 4
MARGIN = 20

module.exports = ->
  @on 'join:after', (e, player) =>
    player.on 'command.snake', (e) =>
      # TODO: use inventory controller function for item-giving
      player.send 0x67,
        windowId: 0
        slot: 36
        item:
          id: 358
          itemCount: 1
          itemDamage: 1337
          nbtData: new Buffer 0
      player.send 0x10,
        slotId: 0

      map = new Map 1337
      snake = [{x: 64, y: 64}]
      add = LENGTH_INCREMENT
      direction = 0
      apple = {}

      updateFps = 14
      drawFps = 16

      updateTimer = null
      drawTimer = null

      draw = ->
        map.sendTo player

      update = ->
        head = _.clone snake[snake.length-1]

        if direction == 0 then head.y--
        else if direction == 1 then head.x--
        else if direction == 2 then head.y++
        else if direction == 3 then head.x++

        for point in snake
          return stop() if point.x == head.x and point.y == head.y
        return stop() if head.x < 0 or head.x > 127 or head.y < 0 or head.y > 127

        for point in snake
          if point.x == apple.x and point.y == apple.y
            add += LENGTH_INCREMENT
            updateFps += SPEED_INCREMENT
            restartTimer()
            placeApple()

        snake.push head
        if add > 0 then add--
        else
          erase = snake.shift()
          map.setPixel 0, erase.x, erase.y

        map.setPixel 44, head.x, head.y

      placeApple = ->
        apple.x = MARGIN + Math.floor Math.random() * (128 - MARGIN)
        apple.y = MARGIN + Math.floor Math.random() * (128 - MARGIN)

        collision = false
        for point in snake
          placeApple() if point.x == apple.x and point.y == apple.y

        map.setPixel 18, apple.x, apple.y

      startTimer = -> updateTimer = setInterval update, 1000 / updateFps
      stopTimer = -> clearInterval updateTimer
      restartTimer = -> stopTimer(); startTimer()

      start = ->
        placeApple()
        startTimer()
        map.sendTo player, true
        drawTimer = setInterval draw, 1000 / drawFps

      stop = ->
        stopTimer()
        clearInterval drawTimer

      player.on 'key.w', -> direction = 0 if direction != 2
      player.on 'key.a', -> direction = 1 if direction != 3
      player.on 'key.s', -> direction = 2 if direction != 0
      player.on 'key.d', -> direction = 3 if direction != 1

      start()
