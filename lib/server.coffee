Component = require './component'

class Server extends Component
    constructor: (@master, iface) ->
        super iface

        # register with master
        @master.request 'init',
            type: 'server'
            interfaceType: @interface.type
            port: @interface.port or @interface,
            (@id) =>

    use: (middleware) => middleware.call @

module.exports = Server