EventEmitter = require('events').EventEmitter

class Interface extends EventEmitter
	constructor: (@remote) ->
		@remote.remote = @ if @remote? and not @remote.remote?

	emit: => @remote._emit.apply @remote, arguments

	_emit: => EventEmitter::emit.apply @, arguments

module.exports = Interface