protocol = require('minecraft-protocol').protocol

convertSlot = (slot) ->
  slot.nbtData = new Buffer slot.nbtData if slot.nbtData?

module.exports = ->

  @on 'connect', (e, server) =>

    server.connection.on 'data', @getClients (clients, id, data) =>
      packet = protocol.get id, false

      for field in packet
        if field.type == 'slot'
          convertSlot data[field.name]
        else if field.type == 'slotArray'
          convertSlot slot for slot in data[field.name]

      for client in clients
        if client?
          try
            client.send id, data
          catch err
            @error new Error "Error sending data to client: (0x#{id.toString 16}) #{err}" if err?