module.exports = ->
  @on 'join:after', (e, player) =>

    player.on 'ready:after', (e) =>
      packet =
        online: true
        ping: 0

      for p in player.region.players.models
        packet.playerName = p.username
        player.send 0xc9, packet

      packet.playerName = player.username
      player.region.send 0xc9, packet

    player.on 'quit:after', (e) =>
      packet =
        playerName: player.username
        online: false
        ping: 0

      player.region.send 0xc9, packet
