mongodb = require 'mongodb'
Db = mongodb.Db

module.exports = (config) ->
  Db.connect config.database, (err, db) =>
    return @error "Error connecting to database: #{err}" if err
    @info 'Connected to database'

    @on 'peer', (e, peer, connection) =>
      connection.respond 'db.insert', (res, collectionName, objects) =>
        collection = db.collection collectionName
        collection.insert objects, {safe:true}, res

      connection.respond 'db.find', (res, collectionName, query, fields, options) =>
        collection = db.collection collectionName
        collection.find(query, fields, options).toArray res

      # TODO: add other methods