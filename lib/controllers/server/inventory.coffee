async = require 'async'
_ = require 'underscore'

# takes in an item or an array of items and converts to send in a packet
toSlot = (input, cb) ->
  return cb null, {id: -1} if not input

  if Array.isArray input
    tasks = []
    for item in input
      ((item) -> tasks.push (cb2) -> toSlot item, cb2)(item)
    async.parallel tasks, cb

  else
    # TODO: handle nbt data
    cb null, input

sendInventory = ->
  toSlot @inventory, (err, items) => @send 0x68, {windowId: 0, items: items}

sendSlot = (slotId) ->
  toSlot @inventory[slotId], (err, item) => @send 0x67, {windowId: 0, slot: slotId, item: item}

# TODO: survival inventory
module.exports = (config) ->
  @on 'join', (e, player) =>
    player.inventory = if player.storage.inventory then _.clone(player.storage.inventory) else []
    player.sendInventory = sendInventory.bind player
    player.sendSlot = sendSlot.bind player

    player.on 'ready', player.sendInventory

    player.on 0x6b, (e, packet) ->
      if 0 <= packet.slot <= 44
        packet.item = null if packet.item.id == -1
        player.inventory[packet.slot] = packet.item

  @on 'quit', (e, player) =>
    player.storage.inventory = player.inventory
