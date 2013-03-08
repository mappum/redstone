Collection = require './collection'

class MapCollection extends Collection
  constructor: (models, options) ->
    if not options? and not (models instanceof Array)
      options = models
      models = null

    super models, options

    @options = options or {}
    @cellSize = @options.cellSize or 32
    @positionKey = @options.positionKey or 'position'
    @grid = []
    @cellMap = {}

  getCell: (model) ->
    position = model[@positionKey]
    x = Math.floor position.x / @cellSize
    z = Math.floor position.z / @cellSize
    col = @grid[x]
    col = @grid[x] = [] if not col
    cell = col[z]
    if not cell
      cell = col[z] = new Collection @options
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
      cell = @getCell(model)
      cell.insert model
      @cellMap[model.id] = cell

  insert: (model) ->
    super model # hehehe
    cell = @getCell model
    cell.insert model
    @cellMap[model.id] = cell
    model.on 'move:after', @onMove

  remove: (model) ->
    super model
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
        cell = @grid[i]?[j]
        cells.push cell.models if cell
    return Array::concat.apply [], cells

module.exports = MapCollection