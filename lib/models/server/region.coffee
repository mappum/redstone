Model = require '../model'

class Region extends Model
	constructor: (options) ->
		super()
		options = options or {}
		@[k] = v for k,v of options

		if not @tickInterval? then @tickInterval = 20

		@ticks = 0
		
		@players = []
		@players.usernames = {}

	start: ->
		if not @tickTimer
			@tickTimer = setInterval @tick.bind @

	stop: ->
		clearInterval @tickTimer
		@tickTimer = null

	tick: ->
		@emit 'tick'
		@ticks++

module.exports = Region