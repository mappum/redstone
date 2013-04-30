_ = require 'underscore'

packAngle = (degrees) ->
  degrees = degrees % 360 + if degrees < 0 then 360 else 0
  Math.floor (degrees - if degrees > 180 then 360 else 0) * (0xff / 360)

updateChunkCoordinates = (player) ->
  player.chunkX = Math.floor player.position.x / 16
  player.chunkZ = Math.floor player.position.z / 16

spawn = (options) ->
  if not options?.handoff?
    @send 0xd, @position

  packet =
    entityId: @entityId
    name: @username
    x: Math.floor @position.x * 32
    y: Math.floor @position.y * 32
    z: Math.floor @position.z * 32
    yaw: packAngle @position.yaw
    pitch: packAngle @position.pitch
    currentItem: 0
    metadata: [
      {key: 0, type: 'byte', value: 0}
      {key: 8, type: 'int', value: 0}
    ]

  @region.send @position, {radius: 64, exclude: [@]}, 0x14, packet

  for p in @region.players.getRadius @, 64
    if p != @
      @send 0x14,
        entityId: p.entityId
        name: p.username
        x: Math.floor p.position.x * 32
        y: Math.floor p.position.y * 32
        z: Math.floor p.position.z * 32
        yaw: packAngle p.position.yaw
        pitch: packAngle p.position.pitch
        currentItem: 0
        metadata: [
          {key: 0, type: 'byte', value: 0}
          {key: 8, type: 'int', value: 0}
        ]

module.exports = (config) ->
  @on 'join:before', (e, player, state) =>
    if not player.position?
      player.position =
        if player.storage.position? then _.clone player.storage.position
        else 
          x: 0
          y: 128
          z: 0
          yaw: 0
          pitch: 0
    player.position.stance = player.position.y + 1.8
    player.position.onGround = false

    updateChunkCoordinates player
    player.spawn = spawn.bind player

  @on 'join:after', (e, player, state) =>
    emitMoving = -> player.emit 'moving'

    onMovement = (e, packet) ->
      d = player.positionDelta = _.clone player.position
      d[k] = (Number(packet[k]) - Number(v)) || 0 for k,v of d

      moved = Math.abs(d.x) > 0.01 or Math.abs(d.y) > 0.01 or Math.abs(d.z) > 0.01
      looked = d.yaw or d.pitch

      if moved or looked
        player.position[k] = Number(player.position[k]) + Number(v) for k,v of d
        player.position.onGround = Boolean player.position.onGround

      player.emit 'look', d if looked

      if moved
        if player.stopped
          player.stopped = false
          player.movingInterval = setInterval emitMoving, 1000 if not player.movingInterval
          player.emit 'start'
        player.emit 'move', d
      else if not player.stopped
        player.stopped = true
        clearInterval player.movingInterval
        player.movingInterval = null
        player.emit 'stop'

    player.on 'toJson', (e, json) ->
      delete json.movingInterval

    player.on 'ready:after', (e) ->
      player.spawn state
      player.on 0xb, onMovement
      player.on 0xc, onMovement
      player.on 0xd, onMovement

    player.on 'quit', (e) =>
      # TODO: save position at other times, too
      player.storage.position = _.pick player.position, 'x', 'y', 'z', 'yaw', 'pitch'
      @emit 'quit', player
      @info "#{player.username} quit (connector:#{player.connector.id})"

    options =
      radius: 64
      exclude: [player]

    player.on 'look', (e, d) ->
      look =
        entityId: player.entityId
        yaw: packAngle player.position.yaw
        pitch: packAngle player.position.pitch
      headYaw = entityId: player.entityId, headYaw: look.yaw
      
      player.region.send player.position, options, 0x20, look
      player.region.send player.position, options, 0x23, headYaw

    player.on 'move:after', ->
      pos =
        entityId: player.entityId
        x: Math.round player.position.x * 32
        y: Math.round player.position.y * 32
        z: Math.round player.position.z * 32
        yaw: packAngle player.position.yaw
        pitch: packAngle player.position.pitch

      player.region.send player.position, options, 0x22, pos

    player.on 'move:after', ->
      lastX = player.chunkX
      lastZ = player.chunkZ

      updateChunkCoordinates player

      if lastX? and (lastX != player.chunkX or lastZ != player.chunkZ)
        player.emit 'moveChunk', player.chunkX, player.chunkZ
