Component = require './component'

class Master extends Component
    constructor: (iface) ->
        super iface

        @on 'peer.connector', (e, connector, connection) =>
            connection.respond 'connection', (res, handshake) =>
                server = @peers.servers[0]

                if server.interfaceType == 'websocket'
                    address = server.connection.socket.handshake.address
                    iface = "#{address.address}:#{server.port}"
                else if server.interfaceType == 'direct'
                    iface = server.port

                res
                    serverId: server.id
                    interfaceType: server.interfaceType
                    interface: iface

module.exports = Master