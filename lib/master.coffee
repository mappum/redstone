Component = require './component'
_ = require 'underscore'

class Master extends Component
    constructor: (config, iface) ->
        super config, iface

        @regions = []
        @regionQueue = []

    start: =>
        # load core modules
        @use require '../lib/controllers/master/db'


        # TODO: load persistent regions
        region = 
            id: 'main'
            type: 'flat'
        @regions.push region
        @regionQueue.push region
        region2 = 
            id: 'main2'
            type: 'flat'
        @regions.push region2
        @regionQueue.push region2

        # TODO: spawn servers to hold regions

        @on 'join', (e, player, res) =>
            @db.findOne 'users', _.pick(player, 'username'), (err, doc) =>
                return @error err if err

                storage = doc?.storage
                player.storage = storage or {
                    region: 'main'
                    # TODO: handle default region
                }

                server = @peers.servers[0]
                # TODO: find correct server

                res _.pick(server, 'id', 'interfaceType', 'interfaceId'), player

                if not storage
                    player.created = Date.now()
                    @db.insert 'users', player, (err) => @error err if err

        @on 'peer.connector', (e, connector, connection) =>
            connection.respond 'connection', (res, player) =>
                @emit 'join', player, res


        @on 'peer.server', (e, server, connection) =>
            server.stats = {}
            server.regions = []

            connection.respond 'newRegion', (res, region) =>
                @regions.push region
                # TODO: spawn server (or select existing server) and tell it about new region
                # TODO: respond info about new region

            connection.respond 'neighbors', (res) =>
                res _.map(_.without(@peers.servers, server), (server) ->
                    output = _.pick server, 'id', 'interfaceType', 'interfaceId'
                    output.regions = _.map server.regions, (region) ->
                        _.pick region, 'id'
                    output)

            connection.on 'update', (data) =>
                server.stats = _.extend server.stats, data
                @debug "got stats from server:#{server.id}"

            # TODO: rethink server region apportionment
            region = @regionQueue.shift()
            if region?
                @info "assigning region:#{region.id} to server:#{server.id}"
                connection.emit 'region', region
                region.server = server
                server.regions.push region

module.exports = Master