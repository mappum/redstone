sock = require '../'

client = sock.connect 'localhost:9000'

client.on 'ping', (arg1, arg2) ->
  console.log 'got ping', arg1, arg2
  @emit 'pong', 1, 2, 3