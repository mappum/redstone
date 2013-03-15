incrementTime = ->
  @time += 20

startTime = ->
  @timeTimer = setInterval @incrementTime, 1000

sendTime = ->
  @send 0x4, {age: [0, @region.ticks], time: [0, @region.time]}

module.exports = ->
  @on 'region:before', (e, region) ->
    region.incrementTime = incrementTime.bind region
    region.startTime = startTime.bind region

    if region.world.time?
      region.time = region.world.time
    else
      region.time = 0
      region.startTime()

  @on 'join:before', (e, player) ->
    player.sendTime = sendTime.bind player
    player.on 'ready', player.sendTime
    player.timeTimer = setInterval player.sendTime, 60 * 1000

    player.on 'leave:before', ->
      clearInterval player.timeTimer
      delete player.timeTimer