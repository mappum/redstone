Client = require './client'
Server = require './server'

module.exports =
  Client: Client
  Server: Server
  connect: (host) -> new Client host
  listen: (port) -> new Server port