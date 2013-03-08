module.exports = (config) ->
  cb = (err) => @error err if err

  @on 'join:before', (e, player) =>
    player.storage = {} if not player.storage?

    player.save = =>
      @master.request 'db.update', 'players', {username: player.username},
        {$set: {storage: player.storage}}, cb