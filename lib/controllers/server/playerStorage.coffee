module.exports = (config) ->
  cb = (err) => @error err if err

  @on 'join:before', (e, player) =>
    player.storage = {} if not player.storage?

    player.save = =>
      @master.request 'db.update', 'users', {username: player.username},
        {$set: {storage: player.storage}}, cb