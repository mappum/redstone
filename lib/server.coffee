Component = require './component'
os = require 'os'

class Server extends Component
  constructor: (config, control, master) ->
    @type = 'server'
    super config, control, master

  start: ->
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
    #@use require '../lib/controllers/server/neighbors'

    super()

    lastUpdate = 0
    updateMaster = =>
      data = 
        loadavg: os.loadavg()
        uptime: os.uptime()
        totalmem: os.totalmem()
        freemem: os.freemem()
        cpus: os.cpus().length
      @emit 'update', data, lastUpdate
      @master.emit 'update', data
      @debug 'sending stats to master'
      lastUpdate = Date.now()

    updateMaster()
    @updateMasterInterval = setInterval updateMaster, 10 * 1000

module.exports = Server