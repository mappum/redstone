Component = require './component'
os = require 'os'

class Server extends Component
    constructor: (config, iface, @master) ->
        super config, iface

    start: =>
        # load core modules
        @use require '../lib/controllers/server/players'
        @use require '../lib/controllers/server/playerStorage'
        @use require '../lib/controllers/server/playerMovement'
        @use require '../lib/controllers/server/regions'
        @use require '../lib/controllers/server/chat'
        @use require '../lib/controllers/server/commands'
        @use require '../lib/controllers/server/inventory'
        @use require '../lib/controllers/server/animation'
        @use require '../lib/controllers/server/chunks'
        @use require '../lib/controllers/server/build'
        @use require '../lib/controllers/server/time'
        @use require '../lib/controllers/server/maps'
        @use require '../lib/controllers/server/keys'
        @use require '../lib/controllers/server/snake'
        @use require '../lib/controllers/server/playerList'
        @use require '../lib/controllers/server/motd'
        @use require '../lib/controllers/server/playerSettings'

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
            @emit 'stats', data
            @master.emit 'update', data
            @debug 'sending stats to master'

        updateMaster()
        @updateMasterInterval = setInterval updateMaster, 10 * 1000

module.exports = Server