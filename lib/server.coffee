Component = require './component'

class Server extends Component
    constructor: (@master, iface) ->
        super iface

        @on 'peer.connector', (e, connector, connection) =>
            connection.on 'join', (player) =>
                player.connector = connection
                player.emit = (id, data) -> connection.emit 'data', player.username, id, data
                @emit 'join', player

        # register with master
        @master.request 'init',
            type: 'server'
            interfaceType: @interface.type
            port: @interface.port or @interface,
            (@id) =>

    use: (middleware) => middleware.call @

module.exports = Server