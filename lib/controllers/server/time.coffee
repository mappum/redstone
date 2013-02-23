module.exports = ->

  @on 'region:before', (e, region) ->
    region.time = 0

    incrementTime = -> region.time = (region.time + 20) % 24000
    region.timeTimer = setInterval incrementTime, 1000

  @on 'join:after', (e, player) ->
    player.on 'ready', ->
      player.send 0x4, {age: [0, player.region.ticks], time: [0, player.region.time]}