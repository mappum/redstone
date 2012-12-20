Base = require './base'

class Server extends Base
    constructor: (@master, @interface) ->
        super(@interface)

        @connectors = []
        @servers = []

        # listen for connections from servers/connectors
        @interface.on 'connection', (connection) =>
            connection.respond 'init', (res, options) =>
                remote = options or {}
                remote.connection = connection

                if remote.type == 'server'
                    id = @servers.length
                    @servers.push remote
                else if remote.type == 'connector'
                    id = @connectors.length
                    @connectors.push remote                    

                @info "incoming connection from #{options.type} #{id}"

            connection.on 'join', (player) =>
                player.connector = connection
                player.emit = (id, data) -> connection.emit 'data', player.username, id, data
                @emit 'join', player

            connection.on 'data', (username, id, data) =>

        # register with master
        @master.request 'init',
            type: 'server'
            interfaceType: @interface.type
            port: @interface.port or @interface,
            (id) => @id = id

    use: (middleware) => middleware.call @

module.exports = Server