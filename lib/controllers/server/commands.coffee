module.exports = ->            
    @on 'message', (e, player, message) =>
        if message.charAt(0) == '/'
            command = message.substr 1
            player.emit 'command', command
            player.emit 'command.'+command
            @emit 'command', player, command
            @emit 'command.'+command, player

            e.halt()