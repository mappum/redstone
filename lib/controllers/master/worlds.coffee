Collection = require '../../models/collection'
World = require '../../models/master/world'

module.exports = (config) ->
  @worlds = new Collection

  @on 'db.ready:after', (e) =>
    @db.ensureIndex 'worlds', {id: 1}

    @db.find 'worlds', {}, (err, worlds) =>
      return @error err if err
      @worlds.insert new World world for world in worlds

      if config.worlds?
        for world in config.worlds
          existing = @worlds.get world.id if world.id?
          @worlds.insert new World world if not existing?