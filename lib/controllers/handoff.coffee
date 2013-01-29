module.exports = ->
    @on 'command.switch', (e, player) =>
        @master.request 'neighbors', (neighbors) =>
            player.handoff neighbors[0], neighbors[0].regions[0]
        e.halt()