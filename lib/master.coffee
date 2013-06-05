Component = require './component'
_ = require 'underscore'

class Master extends Component
  constructor: (config, iface) ->
    @type = 'master'
    super config, iface

  start: ->
    # load core modules
    @use require '../lib/controllers/master/db'
    @use require '../lib/controllers/master/worlds'
    @use require '../lib/controllers/master/regions'
    @use require '../lib/controllers/master/players'
    @use require '../lib/controllers/master/chat'
    @use require '../lib/controllers/master/web'

    @players = 0
    @on 'peer', (e, peer, connection) =>
      peer.stats = {}

      connection.on 'update', (data) =>
        peer.stats = _.extend peer.stats, data
        @debug "got update from #{peer.type}:#{peer.id}"
        @emit "peer.update", peer, peer.stats
        @emit "peer.#{peer.type}.update", peer, peer.stats

    @connectorUpdateTimer = setInterval @updateConnectors, 10 * 1000

  updateConnectors: =>
    @players = 0
    @players += server.stats.players for server in @peers.servers.models

    data =
      players: @players

    connector.connection.emit 'update', data for connector in @peers.connectors.models

module.exports = Master