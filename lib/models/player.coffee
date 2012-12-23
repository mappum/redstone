Model = require './model'

class Player extends Model
	constructor: (options) ->
		super()
		options = options or {}
		@[k] = v for k,v of options

	send: (id, data) =>
		@connector.connection.emit 'data', @username, id, data

module.exports = Player