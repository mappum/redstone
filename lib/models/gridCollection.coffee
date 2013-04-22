Model = require './model'

# a general class for storing things on a static 2d grid (1 model per cell)
class GridCollection extends Model
  constructor: ->
    @cells = {}

  getCol: (x) ->
    col = @cells[x]
    col = @cells[x] = {} if not col?
    col

  set: (model, x, y) ->
    @getCol(x)[y] = model

  get: (x, y) ->
    @cells[x]?[y]

  remove: (x, y) ->
    # delete cell
    if y?
      col = @cells[x]
      if col?
        model = @cells[x][y]
        delete @cells[x][y]
        model

    # delete row/column
    else
      delete @cells[x]

module.exports = GridCollection