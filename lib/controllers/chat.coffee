module.exports = ->
    @broadcast = (message) =>
        player.message message for player in @players
            
    @on 'join', (e, player) =>
        player.message = (message) => player.send 0x3, message: message

        player.on 'data.0x3', (e, data) =>
            player.emit 'message', data.message
            @emit 'message', player, data.message

    @on 'message', (e, player, message) =>
        formatted = "<#{player.username}> #{message}"
        @broadcast formatted
        @info formatted