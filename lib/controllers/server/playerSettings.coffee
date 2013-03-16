module.exports = ->
  @on 'join:before', (e, player) ->
    player.on 0xcc, (e, @settings) ->
      @emit 'settings', @settings