module.exports = ->

  @.on 'connect', (e, server) =>

    server.connection.on 'handoff', @getClient (client, server, region) =>
      if client?
        @connect server.id, server.interfaceType, server.interfaceId, (newServer) =>
          oldServer = client.server
          @debug "handing off #{client.username}/#{client.id} to server:#{newServer.id}"
          client.server.connection.emit 'quit', client.connectionId
          client.server = newServer
          client.region = region
          client.server.connection.emit 'join', client.toJson(), handoff: oldServer.id