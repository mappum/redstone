Model = require '../model'
Player = require './player'
MapCollection = require '../mapCollection'
_ = require 'underscore'

class Region extends Model
	constructor: (options) ->
		super()
		options = options or {}
		@[k] = v for k,v of options

		if not @tickInterval? then @tickInterval = 1000 / 20

		@ticks = 0
		@players = new MapCollection {indexes: ['username'], cellSize: 16}

		# TODO: on chunk unload, remove from chunkList
		@chunkList = []
		@chunkList.push chunk for chunk in options.assignment if options.assignment?

	start: ->
		if not @tickTimer
			@tickTimer = setInterval @tick.bind(@), @tickInterval

	stop: ->
		clearInterval @tickTimer
		@tickTimer = null

	tick: ->
		@emit 'tick'
		@ticks++

	send: (position, options, id, data) ->
		idIndex = 2
		if typeof position == 'number'
			id = position
			data = options
			position = null
			options = null
			idIndex = 0
		else if typeof options == 'number'
			data = id
			id = options
			options = null
			idIndex = 1

		options = options or
			radius: 32
			exclude: null

		players = if not position then @players.models else @players.getRadius position, options.radius
		players = _.difference players, options.exclude if options.exclude

		player.send id, data for player in players

module.exports = Region