Base = require './base'

class Master extends Base
    constructor: (@interface) ->
        super()

        @interface.on 'connection', (connection) =>
            @info 'incoming connection'

            console.log connection

            connection.on 'data', (id) => @info '<< ' + id

module.exports = Master