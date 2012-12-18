Base = require './base'

class Server extends Base
    constructor: (@connector) ->
        super()
        @connector.on 'connection', (connection) => @emit 'join', connection

    use: (middleware) => middleware.call @

module.exports = Server