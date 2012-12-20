var ioc = require('socket.io-client');
var io = require('socket.io').listen(8000);

io.sockets.on('connection', function(socket) {
    console.log('connected');
    socket.on('ping', function(e) {
        socket.emit('pong', e);
    });
});

var c = ioc.connect('http://192.168.0.135:8000');

function ping() {
    var start;
    c.once('pong', function(e) {
        console.log(Date.now() - start);
    });
    start = Date.now();
    c.emit('ping');
}

setInterval(ping, 1000);