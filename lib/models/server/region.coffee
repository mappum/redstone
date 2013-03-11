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
		if not @saveInterval? then @saveInterval = 10 * 1000

		@ticks = 0
		@players = new MapCollection {indexes: ['username'], cellSize: 16}

		@updateChunkList()

	start: ->
		if not @tickTimer
			@tickTimer = setInterval @tick.bind(@), @tickInterval

		if not @saveTimer
			@saveTimer = setInterval @save.bind(@), @saveInterval
		@lastSave = null

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

	save: ->
		for chunk in @chunkList
			do (chunk) =>
				@chunks.getChunk chunk.x, chunk.z, (err, c) =>
					if c.lastUpdate and @lastSave and c.lastUpdate > @lastSave
						@chunks.storeChunk chunk.x, chunk.z
		@lastSave = Date.now()

	updateChunkList: ->
		@chunkList = []
		@chunkList.push chunk for chunk in @assignment if @assignment?

module.exports = Region