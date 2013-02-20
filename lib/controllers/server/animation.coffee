module.exports = ->

  @on 'join:after', (e, player) ->
    player.heldSlot = 0
    player.on 'ready', -> sendHeldItem player

    options =
      radius: 64
      exclude: [player]

    sendHeldItem = ->
      packet =
        entityId: player.entityId
        slot: 0
        item: player.inventory[player.heldSlot+36] or {id: -1}
      player.region.send player.position, options, 0x5, packet

    player.on 0x12, (e, packet) ->
      if packet.animation == 1 and packet.entityId == player.entityId
          player.region.send player.position, options, 0x12, packet

    player.on 0x10, (e, packet) ->
      player.heldSlot = packet.slotId
      sendHeldItem player

    # TODO: broadcast held item when other players join