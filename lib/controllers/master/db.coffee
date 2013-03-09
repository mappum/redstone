mongodb = require 'mongodb'
Db = mongodb.Db

module.exports = (config) ->
  Db.connect config.database, (err, db) =>
    return @error "Error connecting to database: #{err}" if err
    @info 'Connected to database'

    # TODO: make sure calling db.collection every query isn't too slow
    @db =
      find: (collectionName, query, fields, options, cb) =>
        cb = arguments[arguments.length-1] if typeof arguments[arguments.length-1] == 'function'
        collection = db.collection collectionName
        collection.find(query, fields, options).toArray cb

      findOne: (collectionName, query, fields, options, cb) =>
        cb = arguments[arguments.length-1] if typeof arguments[arguments.length-1] == 'function'
        collection = db.collection collectionName
        collection.findOne query, fields, options, cb

      count: (collectionName, query, options, cb) =>
        cb = arguments[arguments.length-1] if typeof arguments[arguments.length-1] == 'function'
        collection = db.collection collectionName
        collection.count query, options, cb

      insert: (collectionName, docs, options, cb) =>
        cb = arguments[arguments.length-1] if typeof arguments[arguments.length-1] == 'function'
        options = options or {}
        options.safe = true if not options.safe?
        collection = db.collection collectionName
        collection.insert docs, options, cb

      update: (collectionName, crtiteria, objNew, options, cb) =>
        cb = arguments[arguments.length-1] if typeof arguments[arguments.length-1] == 'function'
        options = options or {}
        options.safe = true if not options.safe?
        collection = db.collection collectionName
        collection.update crtiteria, objNew, options, cb

      remove: (collectionName, selector, options, cb) =>
        cb = arguments[arguments.length-1] if typeof arguments[arguments.length-1] == 'function'
        options = options or {}
        options.safe = true if not options.safe?
        collection = db.collection collectionName
        collection.remove crtiteria, objNew, options, cb

      ensureIndex: (collectionName, keys, options, cb) =>
        cb = arguments[arguments.length-1] if typeof arguments[arguments.length-1] == 'function'
        collection = db.collection collectionName
        collection.ensureIndex keys, options, cb

      # TODO: add other methods if needed

    # listen for peer db requests
    @on 'peer', (e, peer, connection) =>
      for name, method of @db
        ((name, method) =>
          connection.respond 'db.'+name, (res) =>
            args = Array::slice.call arguments, 1
            args.push res
            method.apply @, args
        )(name, method)

    @emit 'db.ready'