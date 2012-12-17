#!/usr/bin/env coffee

Server = require '../lib/server'
Connector = require '../lib/connector'
Interface = require '../lib/interface'

# logging
winston = require 'winston'
logger = new winston.Logger
	transports: [
    	new winston.transports.Console
    		colorize: true
    ]
winston.addColors
	debug: 'white'
	info: 'cyan'
	warn: 'yellow'
	error: 'red'

serverInterface = new Interface
server = new Server serverInterface
server.on 'log', (level, message) -> logger.log level, "[server] #{message}"

connector = new Connector(
    new Interface(serverInterface),
    requireAuth: false
)
connector.on 'log', (level, message) -> logger.log level, "[connector] #{message}"