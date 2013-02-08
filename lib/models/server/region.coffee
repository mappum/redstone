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

	start: =>
		if not @ticking
			@ticking = true
			@tick()

	stop: => @ticking = false

	tick: =>
		@emit 'tick'
		@ticks++
		setTimeout @tick, @tickInterval if @ticking

module.exports = Region