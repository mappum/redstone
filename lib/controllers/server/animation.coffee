module.exports = ->

  sendHeldItem = (player) ->
    packet =
      entityId: player.entityId
      slot: 0
      item: player.inventory[player.heldSlot+36] or {id:-1}
    # TODO: use broadcast method when written
    for p in player.region.players.models
      p.send 0x5, packet if p != player

  @on 'join:after', (e, player) ->
    player.heldSlot = 0
    player.on 'ready', -> sendHeldItem player

    player.on 0x12, (e, packet) ->
      if packet.animation == 1 and packet.entityId == player.entityId
        # TODO: use broadcast method when written
        for p in player.region.players.models
          p.send 0x12, packet if p != player

    player.on 0x10, (e, packet) ->
      player.heldSlot = packet.slotId
      sendHeldItem player

    # TODO: broadcast held item when other players join