sock = require '../'

client = sock.connect 'localhost:9000'

client.on 'ping', (arg1, arg2, arg3) ->
  console.log 'got ping', arguments
  @emit 'pong', 1, 2, 3