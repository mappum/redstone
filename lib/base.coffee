events = require 'events'

class Base extends events.EventEmitter
	debug: (message) => @emit 'debug', message
	info: (message) => @emit 'info', message
	warn: (message) => @emit 'warn', message
	error: (message) => @emit 'error', message

module.exports = Base