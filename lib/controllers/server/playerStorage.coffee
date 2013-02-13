watchjs = require 'watchjs'

module.exports = (config) ->
  delay = config.persistence?.delay or 5 * 1000
  cb = (err) => @error err if err

  @on 'join', (e, player) =>
    player.storage = {} if not player.storage?
    timer = null

    update = ->
      timer = null
      @master.request 'db.update', {username: player.username}, player.storage, cb

    watchjs.watch player.storage, ->
      timer = setTimeout update, delay if not timer