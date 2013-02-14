watchjs = require 'watchjs'

module.exports = (config) ->
  delay = config.persistence?.delay or 5 * 1000
  cb = (err) => @error err if err

  @on 'join', (e, player) =>
    player.storage = {} if not player.storage?
    timeout = null

    player.save = =>
      if timeout
        clearTimeout timeout
        timeout = null

      @master.request 'db.update', 'users', {username: player.username},
        {$set: {storage: player.storage}}, cb

    watchjs.watch player.storage, ->
      timeout = setTimeout player.save, delay if not timeout