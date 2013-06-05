express = require 'express'
_ = require 'underscore'

module.exports = (config) ->
  app = express()
  app.use express.static __dirname+'/../../web'

  app.get '/worlds', (req, res) =>
    res.json @worlds.models

  app.listen config.webPort or 80