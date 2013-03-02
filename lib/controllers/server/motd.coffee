module.exports = (config) ->
  motd = config.motd

  if motd?
    motd = [motd] if typeof motd == 'string'

    @on 'join:after', (e, player) ->
      player.on 'ready:after', ->
        player.message message for message in motd