module.exports = ->
    @on 'join:before', (e, player) =>
        handoff = (server, region) ->
            @emit 'quit'
            @_send 'handoff', server, region

        player.handoff = handoff.bind player

    @on 'command.switch', (e, player) =>
        @master.request 'neighbors', (neighbors) =>
            player.handoff neighbors[0], neighbors[0].regions[0]
        e.halt()