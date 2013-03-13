net = require 'net'
EventEmitter = require('events').EventEmitter
msgpack = require 'msgpack-js'

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

  onData: (data) ->
    @buffer = Buffer.concat [@buffer, data]

    offset = 0
    while offset < @buffer.length
      unpacked = @unpack @buffer
      return if not unpacked
      offset += unpacked.size
      @buffer = @buffer.slice unpacked.size
      @_emit.apply @, unpacked

  emit: ->
    buffer = @pack.apply @, Array::slice.call(arguments, 0)
    @socket.write buffer

  unpack: (data) ->
    eventLength = data.readUInt8 0
    event = data.toString 'utf8', 1, eventLength + 1
    argN = data.readUInt8 eventLength + 1
    args = [event]
    offset = eventLength + 2

    for i in [0...argN]
      argLength = data.readUInt32LE offset
      offset += 4
      return false if argLength + offset > data.length
      args.push msgpack.decode data.slice offset, offset + argLength
      offset += argLength

    args.size = offset
    args

  pack: (event) ->
    args = Array::slice.call arguments, 1

    header = new Buffer 1 + event.length + 1
    header.writeUInt8 event.length, 0
    header.write event, 1, event.length
    header.writeUInt8 args.length, 1 + event.length

    length = header.length
    buffers = [header]

    for arg in args
      buffer = msgpack.encode arg
      lengthBuffer = new Buffer 4
      lengthBuffer.writeUInt32LE buffer.length, 0
      buffers.push lengthBuffer
      buffers.push buffer
      length += 4 + buffer.length

    Buffer.concat buffers, length
 
module.exports = Client