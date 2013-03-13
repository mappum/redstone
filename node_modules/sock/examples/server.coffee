sock = require '../'

server = sock.listen 9000
server.on 'connection', (client) ->
  console.log 'incoming connection'

  client.on 'pong', -> console.log 'got pong'
  client.emit 'ping', {hello: 'world'}, 'another argument'