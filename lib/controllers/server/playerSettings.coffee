module.exports = ->
  @on 'join:after', (e, player) ->
    player.on 0xcc, (e, @settings) ->
      @emit 'settings', @settings