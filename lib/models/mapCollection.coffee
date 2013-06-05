Collection = require './collection'
GridCollection = require './gridCollection'

class MapCollection extends Collection
  constructor: (models, options) ->
    if not options? and not (models instanceof Array)
      options = models
      models = null

    super models, options

    @options = options or {}
    @cellSize = @options.cellSize or 32
    @positionKey = @options.positionKey or 'position'
    @grid = new GridCollection
    @cellMap = {}

    @onMove = @onMove.bind @

  getCell: (model) ->
    position = model[@positionKey]
    x = Math.floor position.x / @cellSize
    z = Math.floor position.z / @cellSize
    cell = @grid.get x, z
    if not cell
      cell = new Collection @options
      @grid.set cell, x, z
      cell.x = x
      cell.z = z
    return cell

  onMove: (e) =>
    model = e.origin
    position = model[@positionKey]
    cell = @cellMap[model.id]
    x = Math.floor position.x / @cellSize
    z = Math.floor position.z / @cellSize
    if x != cell.x or z != cell.z
      cell.remove model
      cell = @getCell model
      cell.insert model
      @cellMap[model.id] = cell

  insert: (model) ->
    super model # hehehe
    cell = @getCell model
    cell.insert model
    @cellMap[model.id] = cell
    model.on 'move:after', @onMove

  remove: (model) ->
    model = super model
    @cellMap[model.id].remove model
    delete @cellMap[model.id]
    model.off 'move:after', @onMove

  getRadius: (model, radius) ->
    position = if model[@positionKey]? then model[@positionKey] else model
    x = Math.floor position.x / @cellSize
    z = Math.floor position.z / @cellSize
    range = Math.ceil radius / @cellSize
    cells = []
    for i in [x-range..x+range]
      for j in [z-range..z+range]
        # TODO: check if models are in radius?
        cell = @grid.get i, j
        cells.push cell.models if cell?
    return Array::concat.apply [], cells

module.exports = MapCollection