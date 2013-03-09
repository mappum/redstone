module.exports = (config) ->
  motd = config.motd

  if motd?
    motd = [motd] if typeof motd == 'string'

    @on 'join:after', (e, player, options) ->
      if not options.handoff?
        player.on 'ready:after', ->
          player.message message for message in motd