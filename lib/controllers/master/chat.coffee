module.exports = ->
  @on 'peer.server', (e, server, connection) =>
    connection.on 'message', (message) =>
      for s in @peers.servers.models
        s.connection.emit 'message', message if s != server