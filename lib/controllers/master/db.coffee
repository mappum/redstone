mongodb = require 'mongodb'
Db = mongodb.Db

module.exports = (config) ->
  Db.connect config.database, (err, db) =>
    return @error "Error connecting to database: #{err}" if err
    @info 'Connected to database'

    @on 'peer', (e, peer, connection) =>
      connection.respond 'db.find', (res, collectionName, query, fields, options) =>
        collection = db.collection collectionName
        collection.find(query, fields, options).toArray res

      connection.respond 'db.findOne', (res, collectionName, query, fields, options) =>
        collection = db.collection collectionName
        collection.findOne query, fields, options, res

      connection.respond 'db.count', (res, collectionName, query, options) =>
        collection = db.collection collectionName
        collection.count query, options, res

      connection.respond 'db.insert', (res, collectionName, docs, options) =>
        options = options or {}
        options.safe = true if not options.safe?
        collection = db.collection collectionName
        collection.insert docs, options, res

      connection.respond 'db.update', (res, collectionName, crtiteria, objNew, options) =>
        options = options or {}
        options.safe = true if not options.safe?
        collection = db.collection collectionName
        collection.update crtiteria, objNew, options, res

      connection.respond 'db.remove', (res, collectionName, selector, options) =>
        options = options or {}
        options.safe = true if not options.safe?
        collection = db.collection collectionName
        collection.remove crtiteria, objNew, options, res

      connection.respond 'db.ensureIndex', (res, collectionName, keys, options) =>
        collection = db.collection collectionName
        collection.ensureIndex keys, options, res

      # TODO: add other methods if needed