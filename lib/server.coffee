Component = require './component'
os = require 'os'

class Server extends Component
    constructor: (@master, iface) ->
        super iface

    use: (middleware) => middleware.call @

    start: =>
        # register with master
        @master.request 'init',
            type: 'server'
            interfaceType: @interface.type
            port: @interface.port or @interface,
            (@id) =>

        updateMaster = =>
            data = 
                loadavg: os.loadavg()
                uptime: os.uptime()
                totalmem: os.totalmem()
                freemem: os.freemem()
                cpus: os.cpus().length
            @master.emit 'update', data
            @debug 'sending stats to master'

        updateMaster()
        @updateMasterInterval = setInterval updateMaster, 60 * 1000

module.exports = Server