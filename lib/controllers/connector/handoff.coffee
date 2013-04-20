module.exports = ->

  @.on 'connect', (e, server) =>

    server.connection.on 'handoff', @getClients (clients, server, player, options) =>
      client = clients[0]
      if client?
        @connect server, (newServer) =>
          oldServer = client.server
          @debug "handing off #{client.username}/#{client.id} to server:#{newServer.id}"
          client.server = newServer
          client.server.connection.emit 'join', player, options