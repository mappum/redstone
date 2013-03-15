net = require 'net'
EventEmitter = require('events').EventEmitter

removeBuffers = (args) ->
  output = {length: 0}
  for arg, i in args
    if arg instanceof Buffer
      output.length++
      output[i+1] = arg
      args[i] = null
    else if typeof arg == 'object' and not (arg instanceof Array)
      for k, v of arg
        if v instanceof Buffer
          output.length++
          output["#{i+1}.#{k}"] = v
          arg[k] = null
  output

class Client extends EventEmitter
  _emit: EventEmitter::emit

  constructor: (host = 'localhost') ->
    if typeof host == 'string' or typeof host == 'number'
      if typeof host == 'string'
        split = host.split ':'

        host = split[0]
        port = split[1] or 8000
      else port = host

      @socket = net.connect port, host

    else if host instanceof net.Socket
      @socket = host

    else
      throw new Error 'Invalid host argument, must be a string, number, or net.Socket'

    @buffer = new Buffer 0
    @socket.on 'data', @onData.bind(@)
    @socket.setNoDelay()

  onData: (data) ->
    @buffer = if @buffer? then Buffer.concat [@buffer, data] else data

    offset = 0
    while @buffer? and offset < @buffer.length
      unpacked = @unpack @buffer
      return if not unpacked
      offset += unpacked.size
      @buffer = @buffer.slice unpacked.size
      @buffer = null if @buffer.length == 0
      @_emit.apply @, unpacked

  emit: ->
    buffer = @pack.apply @, Array::slice.call(arguments, 0)
    @socket.write buffer

  getArg: (data, offset) ->
      argLength = data.readUInt32LE offset
      offset += 4
      return false if argLength + offset > data.length
      return {
        arg: JSON.parse data.slice(offset, offset + argLength).toString('utf8')
        offset: offset + argLength
      }

  unpack: (data) ->
    eventLength = data.readUInt8 0
    event = data.toString 'utf8', 1, eventLength + 1
    argN = data.readUInt8 eventLength + 1
    args = [event]
    offset = eventLength + 2

    for i in [0...argN]
      res = @getArg data, offset
      if res == false then return false
      else
        offset = res.offset
        args.push res.arg

    res = @getArg data, offset
    if res == false then return false
    else
      offset = res.offset
      bufferIndex = res.arg

    for b, i in bufferIndex
      return false if b.l + offset > data.length
      split = b.k.split '.'
      cursor = args
      for token, i in split
        if i == split.length - 1
          cursor[token] = data.slice offset, offset + b.l
          offset += b.l
        else
          cursor = cursor[token]

    args.size = offset
    args

  pack: (event) ->
    args = Array::slice.call arguments, 1
    buffers = removeBuffers args
    bufferN = buffers.length
    delete buffers.length

    header = new Buffer 1 + event.length + 1
    header.writeUInt8 event.length, 0
    header.write event, 1, event.length
    header.writeUInt8 args.length, 1 + event.length

    length = header.length
    output = [header]

    bufferIndex = []
    args.push bufferIndex

    for k, buffer of buffers
      bufferIndex.push l: buffer.length, k: k

    for arg in args
      string = JSON.stringify arg
      stringLength = Buffer.byteLength string
      buffer = new Buffer stringLength + 4
      buffer.writeUInt32LE stringLength, 0
      buffer.write string, 4
      output.push buffer
      length += buffer.length

    for k, buffer of buffers
      output.push buffer
      length += buffer.length

    Buffer.concat output, length
 
module.exports = Client