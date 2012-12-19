Base = require './base'

class Server extends Base
    constructor: (@master, @interface) ->
        super()

        @connectors = []
        @servers = []

        # listen for connections from servers/connectors
        @interface.on 'connection', (connection) =>
            connection.respond 'init', (res, options) =>
                remote = options
                remote.connection = connection

                if remote.type == 'server'
                    id = @servers.length
                    @servers.push remote
                else if remote.type == 'connector'
                    id = @connectors.length
                    @connectors.push remote

                @info "incoming connection from #{options.type} #{id}"

        # register with master
        @master.request 'init',
            type: 'server'
            interface: @interface.handle
            interfaceType: @interface.type,
            (id) => @id = id

    use: (middleware) => middleware.call @

module.exports = Server