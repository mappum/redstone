EventEmitter = require('events').EventEmitter

class Interface extends EventEmitter
	constructor: (@remote) ->
		@remote.remote = @ if @remote? and not @remote.remote?

	_emit: EventEmitter::emit

	emit: => if @remote? then @remote._emit.apply @remote, arguments


module.exports = Interface