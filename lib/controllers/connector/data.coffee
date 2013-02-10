module.exports = ->

  @.on 'connect', (e, server) =>

    server.connection.on 'data', @getClient (client, id, data) ->
      if client? then client.send id, data