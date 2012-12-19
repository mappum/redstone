Base = require './base'

class Master extends Base
    constructor: (@interface) ->
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

                if remote.type == 'connector'
                    connection.respond 'connection', (res, handshake) =>
                        res
                            serverId: @servers[0].id
                            interfaceType: @servers[0].interfaceType
                            interface: @servers[0].interface

                res id

module.exports = Master