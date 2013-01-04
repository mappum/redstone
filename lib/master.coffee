Component = require './component'
_ = require 'underscore'

class Master extends Component
    constructor: (iface) ->
        super iface

        @regions = []
        @regionQueue = []

        # TODO: load persistent regions
        region = 
            id: 'main'
            type: 'flat'
        @regions.push region
        @regionQueue.push region
        # TODO: spawn servers to hold regions

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
                    state: # TODO: lookup actual state
                        regionId: @regions[0].id

        @on 'peer.server', (e, server, connection) =>
            server.stats = {}

            connection.respond 'newRegion', (res, region) =>
                @regions.push region
                # TODO: spawn server (or select existing server) and tell it about new region
                # TODO: respond info about new region

            connection.on 'update', (data) =>
                server.stats = _.extend server.stats, data
                @debug "got stats from server:#{server.id}"

            # TODO: rethink server region apportionment
            region = @regionQueue.shift()
            if region?
                @info "assigning region:#{region.id} to server:#{server.id}"
                connection.emit 'region', region
                region.server = server

module.exports = Master