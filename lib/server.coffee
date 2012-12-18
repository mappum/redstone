Base = require './base'

class Server extends Base
    constructor: (@connector) ->
        super()
        @connector.on 'connection', (connection) => @emit 'join', connection, @connector

    use: (middleware) => middleware.call @

module.exports = Server