Base = require './base'

class Master extends Base
    constructor: (@interface) ->
        super()

        # on connections from servers/connectors
        @interface.on 'connection', (connection) =>
            @info 'incoming connection'

            connection.respond 'connection', (res, handshake) =>
                res 'foo'

module.exports = Master