#!/usr/bin/env coffee

program = require 'commander'

program
    .version('0.0.0')
    .option('-c, --connector [port]', 'Run a connector instance, and optionally specify a port')
    .option('-s, --server', 'Run a server instance')
    .option('-m, --master [master]', 'Run a master instance, or specify a master to connect to')
    .option('-S, --suppress', 'Supress logging')
    .option('-v, --verbose', 'Log more detailed stuff')
    .option('--config [file]', 'Loads the specified config file', '../config')
    .parse process.argv

if program.config? then config = require program.config
else config = {}

config.connector = program.connector if program.connector?
config.server = program.server if program.server?
config.master = program.master if program.master?

# if no components specified, run them all
if not config.connector and not config.server and not config.master
    config.connector = config.server = config.master = true

# check if more than one component is running
if Number(config.connector?) + Number(config.server) + Number(config.master == true) > 1
    multipleComponents = true

# we either need a master to connect to, or we should run a local master
if not config.master?
    console.log 'You must either specify a master to connect to or run a master instance'
    program.help()

# logging
winston = require 'winston'
levels =
    debug: 0
    info: 1
    warn: 2
    error: 3
colors =
    debug: 'white'
    info: 'cyan'
    warn: 'yellow'
    error: 'red'
transports = []
transports.push new winston.transports.Console
    colorize: true
    level: if program.suppress then 'error' else if program.verbose then 'debug' else 'info'
logger = new winston.Logger transports: transports, levels: levels
winston.addColors colors

# if running a local master, use direct interface, otherwise use websocket
Interface = require '../lib/interface'
Interface = Interface.websocket if config.master != true or (config.master == true and not multipleComponents)

# start components
if config.master == true
    logger.info 'Initializing master'

    Master = require '../lib/master'

    master = new Master(new Interface().listen(8000))
    master.on 'log', (e, level, message) ->
        logger.log level, (if multipleComponents then '[master] ' else '') + message
    
masterInterface = if config.master == true then master.interface else config.master

if config.server
    logger.info 'Initializing server'

    Server = require '../lib/server'

    server = new Server(new Interface(masterInterface), new Interface().listen(8001))
    server.on 'log', (e, level, message) ->
        logger.log level, (if multipleComponents then '[server] ' else '') + message

    # TODO: handle module loading
    server.use require '../lib/controllers/players'
    server.use require '../lib/controllers/regions'
    server.use require '../lib/controllers/chat'
    server.use require '../lib/controllers/commands'

    server.start()

if config.connector
    logger.info 'Initializing connector'

    Connector = require '../lib/connector'

    connector = new Connector(new Interface(masterInterface),
        requireAuth: config.requireAuth or false
        port: if config.connector != true then Number(config.connector)
    )
    connector.on 'log', (e, level, message) ->
        logger.log level, (if multipleComponents then '[connector] ' else '') + message

setInterval ->
  0
, 1000 * 1000