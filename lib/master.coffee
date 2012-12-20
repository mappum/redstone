Base = require './base'

class Master extends Base
    constructor: (@interface) ->
        super()

        @connectors = []
        @servers = []

        # listen for connections from servers/connectors
        @interface.on 'connection', (connection) =>
            connection.respond 'init', (res, options) =>
                remote = options or {}
                remote.connection = connection

                if remote.type == 'server'
                    remote.id = @servers.length
                    @servers.push remote
                else if remote.type == 'connector'
                    remote.id = @connectors.length
                    @connectors.push remote

                @info "incoming connection from #{options.type} #{remote.id}"

                if remote.type == 'connector'
                    connection.respond 'connection', (res, handshake) =>
                        if @servers[0].interfaceType == 'websocket'
                            address = @servers[0].connection.socket.handshake.address
                            iface = "http://#{address.address}:#{@servers[0].port}"
                        else if @servers[0].interfaceType == 'direct'
                            iface = @servers[0].port

                        res
                            serverId: @servers[0].id
                            interfaceType: @servers[0].interfaceType
                            interface: iface
                res remote.id

module.exports = Master