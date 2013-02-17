module.exports = ->
  @on 'join', (e, player) ->

    player.on 0x12, (e, packet) ->
      if packet.animation == 1 and packet.entityId == player.entityId
        # TODO: use broadcast method when written
        for p in player.region.players
          p.send 0x12, packet if p != player

    player.on 0x10, (e, packet) ->
        packet =
          entityId: player.entityId
          slot: 0
          item: player.inventory[packet.slotId+36] or {id:-1}
        # TODO: use broadcast method when written
        for p in player.region.players
          p.send 0x5, packet if p != player