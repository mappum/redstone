text = require('minecraft-net').text

module.exports = ->
    @broadcast = (message) =>
        player.message message for player in @players
            
    @on 'join:before', (e, player) ->
        player.message = (message) => player.send 0x3, message: message

    @on 'join', (e, player) =>
        @broadcast text.yellow + "#{player.username} joined the game"

        player.on 'data.0x3', (e, data) =>
            player.emit 'message', data.message
            @emit 'message', player, data.message

    @on 'quit', (e, player) =>
        @broadcast text.yellow + "#{player.username} left the game"

    @on 'message', (e, player, message) =>
        formatted = "<#{player.username}> #{message}"
        @broadcast formatted
        @info formatted