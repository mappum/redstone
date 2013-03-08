Collection = require '../../models/collection'
World = require '../../models/master/world'

module.exports = (config) ->
  @worlds = new Collection

  @on 'db.ready:after', (e) =>
    @db.ensureIndex 'worlds', {id: 1}, ->

    # TODO: load worlds from config

    @db.find 'worlds', {}, (err, worlds) =>
      return @error err if err
      @worlds.insert new World world for world in worlds