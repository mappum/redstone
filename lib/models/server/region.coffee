Model = require '../model'
Player = require './player'
MapCollection = require '../mapCollection'
_ = require 'underscore'

class Region extends Model
	constructor: (options) ->
		super()
		options = options or {}
		@[k] = v for k,v of options

		if not @tickInterval? then @tickInterval = 20

		@ticks = 0
		
		@players = new MapCollection null, {indexes: ['username']}

	start: ->
		if not @tickTimer
			@tickTimer = setInterval @tick.bind @

	stop: ->
		clearInterval @tickTimer
		@tickTimer = null

	tick: ->
		@emit 'tick'
		@ticks++

	send: (position, options, event) ->
		eventIndex = 2
		if typeof position == 'string'
			event = position
			position = null
			options = null
			eventIndex = 0
		else if typeof options == 'string'
			event = options
			options = null
			eventIndex = 1

		options = options or
			radius: 32
			exclude: null

		players = if not position then @players.models else @players.getRadius position, options.radius
		players = _.difference players, options.exclude if options.exclude

		args = Array::slice.call arguments, eventIndex
		player.send.apply player, args for player in players

module.exports = Region