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

        @on 'peer.server', (e, server, connection) =>
            server.stats = {}
            server.regions = []

            connection.on 'update', (data) =>
                server.stats = _.extend server.stats, data
                @debug "got stats from server:#{server.id}"

module.exports = Master