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

    # on item drop (q)
    player.on 0xe, (e, packet) ->
      if packet.status == 4
        # TODO: use inventory controller remove method when implemented
        player.inventory[player.heldSlot+36] = null
        player.sendSlot player.heldSlot+36

        # TODO: finish the item entity code below
        ###
        # TODO: make a utility function somewhere to get facing component vector
        magnitude = 1

        yaw = player.position.yaw % 360
        yaw += 360 if yaw < 0
        yaw = 360 - yaw

        pitch = player.position.pitch % 360
        pitch += 360 if pitch < 0
        pitch = 360 - pitch

        vX = magnitude * Math.sin yaw * Math.PI / 180
        vY = magnitude * Math.sin pitch * Math.PI / 180
        vZ = magnitude * Math.cos yaw * Math.PI / 180

        player.send 0x17,
          entityId: Math.floor Math.random() * 0xfffffff
          type: 2
          x: Math.floor player.position.x * 32
          y: Math.floor (player.position.y + 1.3) * 32
          z: Math.floor player.position.z * 32
          yaw: 0
          pitch: 0
          objectData:
            intField: 1
            velocityX: Math.floor vX * 1024
            velocityY: Math.floor vY * 1024
            velocityZ: Math.floor vZ * 1024
          ###

  @on 'quit', (e, player) =>
    player.storage.inventory = player.inventory
