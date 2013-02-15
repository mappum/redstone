module.exports = ->
  @on 'join', (e, player) ->
    player.on 0x12, (e, packet) ->
      if packet.animation == 1 and packet.entityId == player.entityId
        # TODO: use broadcast method when written
        for p in player.region.players
          p.send 0x12, packet if p != player
