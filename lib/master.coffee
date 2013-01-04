Component = require './component'
_ = require 'underscore'

class Master extends Component
    constructor: (iface) ->
        super iface

        @on 'peer.connector', (e, connector, connection) =>
            connection.respond 'connection', (res, handshake) =>
                server = @peers.servers[0]
                # TODO: lookup position and find correct server

                if server.interfaceType == 'websocket'
                    address = server.connection.socket.handshake.address
                    iface = "#{address.address}:#{server.port}"
                else if server.interfaceType == 'direct'
                    iface = server.port

                res
                    serverId: server.id
                    interfaceType: server.interfaceType
                    interface: iface

        @on 'peer.server', (e, server, connection) =>
            server.stats = {}

            connection.on 'update', (data) =>
                server.stats = _.extend server.stats, data
                @debug "got stats from server:#{server.id}"


module.exports = Master