module.exports = ->
  
  sendHeldItem = (player, slotId) ->
    packet =
      entityId: player.entityId
      slot: 0
      item: player.inventory[slotId+36] or {id:-1}
    # TODO: use broadcast method when written
    for p in player.region.players
      p.send 0x5, packet if p != player

  @on 'join', (e, player) ->
    setTimeout ->
      sendHeldItem player, 0
    , 600

    player.on 0x12, (e, packet) ->
      if packet.animation == 1 and packet.entityId == player.entityId
        # TODO: use broadcast method when written
        for p in player.region.players
          p.send 0x12, packet if p != player

    player.on 0x10, (e, packet) -> sendHeldItem player, packet.slotId