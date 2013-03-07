Component = require './component'
_ = require 'underscore'

class Master extends Component
    constructor: (config, iface) ->
        super config, iface

    start: =>
        # load core modules
        @use require '../lib/controllers/master/db'
        @use require '../lib/controllers/master/regions'
        @use require '../lib/controllers/master/players'

        @players = 0
        @on 'peer.server', (e, server, connection) =>
            server.stats = {}
            server.regions = []

            connection.on 'update', (data) =>
                server.stats = _.extend server.stats, data
                @debug "got stats from server:#{server.id}"

        @connectorUpdateTimer = setInterval @updateConnectors, 10 * 1000

    updateConnectors: =>
        @players = 0
        @players += server.stats.players for server in @peers.servers.models

        data =
            players: @players

        connector.connection.emit 'update', data for connector in @peers.connectors.models

module.exports = Master