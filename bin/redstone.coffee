#!/usr/bin/env coffee

Server = require '../lib/server'
Connector = require '../lib/connector'
Interface = require '../lib/interface'
mcnet = require 'minecraft-net'
text = mcnet.text

serverInterface = new Interface
server = new Server serverInterface

connector = new Connector(
    new Interface(serverInterface),
    requireAuth: false
)