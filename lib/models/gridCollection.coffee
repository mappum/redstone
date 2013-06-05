Model = require './model'

# a general class for storing things on a static 2d grid (1 model per cell)
class GridCollection extends Model
  constructor: (cells) ->
    @rows = {}
    @cols = {}

    if cells?
      for x, col of cells
        @update x, 'x'
        @update y, 'y' for y of col

    else @width = @height = 0

    @cells = cells?.cells or cells or {}

  getCol: (x) ->
    col = @cells[x]
    col = @cells[x] = {} if not col?
    col

  set: (model, x, y) ->
    col = @getCol(x)
    if not col[y]?
      @update x, 'x'
      @update y, 'y'

    col[y] = model

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

    @update x, 'x', true
    @update y, 'y', true

  # based on the coordinate and axis we are adding/removing an item at,
  # update the min/max/size
  update: (value, axis, remove) ->
    value = +value
    axis = axis.toUpperCase()

    if not remove
      @['min'+axis] = value if not @['min'+axis] or @['min'+axis] > value
      @['max'+axis] = value if not @['max'+axis] or @['max'+axis] < value

    if axis == 'X'
      sizeKey = 'width'
      dimensionKey = 'cols'
    else if axis == 'Y'
      sizeKey = 'height'
      dimensionKey = 'rows'

    @[sizeKey] = @['max'+axis] - @['min'+axis] + 1
    
    if not remove
      if not @[dimensionKey][value]? then @[dimensionKey][value] = 1
      else @[dimensionKey][value]++

    else
      # find new min/max if neccessary
      if --@[dimensionKey][value] <= 0
        min = true if value == @['min'+axis]
        max = true if value == @['max'+axis]

        if min or max
          if --@[sizeKey] <= 0
            @['min'+axis] = @['max'+axis] = undefined

          else
            if min
              for i in [value+1..@['max'+axis]]
                if @[dimensionKey][i]
                 @['min'+axis] = i
                 break
            else if max
              for i in [value-1..@['min'+axis]]
                if @[dimensionKey][i]
                 @['max'+axis] = i
                 break

            @[sizeKey] = @['max'+axis] - @['min'+axis] + 1

module.exports = GridCollection