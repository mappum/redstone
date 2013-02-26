fs = require 'fs'
Chunk = require '../models/server/chunk'

module.exports = (path) ->
  getFilename = (x, z) -> path + "/#{x}.#{z}.chunk"

  get: (x, z, cb) ->
    filename = getFilename(x, z)
    fs.exists filename, (exists) ->
      if exists
        fs.readFile filename, (err, data) ->
          return cb err if err
          cb null, new Chunk data
      else cb null

  set: (chunk, x, z, cb) ->
    fs.writeFile getFilename(x, z), chunk.buf, cb

