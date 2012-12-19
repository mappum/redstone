Base = require './base'

class Server extends Base
    constructor: (@master, @interface) ->
        super()

        # listen for peers/connectors
        @interface.on 'connection', (connection) =>
            console.log connection

        # register with master
        @master.request 'init',
            type: 'server'
            interface: @interface.handle
            interfaceType: @interface.type,
            (id) =>

    use: (middleware) => middleware.call @

module.exports = Server