updatePing = ->
  @ping (latency) =>
    @latency = latency

    packet =
      online: true
      ping: latency

    packet.playerName = @username
    @region.send 0xc9, packet

module.exports = ->
  @on 'join:after', (e, player) =>
    player.updatePing = updatePing.bind player
    pingTimer = null

    player.on 'ready:after', (e) =>
      player.updatePing()
      pingTimer = setInterval player.updatePing, 30 * 1000

      packet = online: true

      for p in player.region.players.models
        packet.playerName = p.username
        packet.ping = p.latency or 0
        player.send 0xc9, packet

    player.on 'quit:after', (e) =>
      packet =
        playerName: player.username
        online: false
        ping: 0

      player.region.send 0xc9, packet