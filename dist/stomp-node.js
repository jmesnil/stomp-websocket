var Stomp = require("./stomp");
var net = require('net');

var wrap = function(port, host) {
  var ws = {
    url: 'tcp:// ' + host + ':' + port
  };
  var socket = net.connect(port, host, function(e) {
    ws.onopen();
  });
  socket.on('close', function(e) {
    if (ws.onclose) {
      ws.onclose();
    }
  });
  socket.on('data', function(d) {
    var event = {
      'data': d.toString()
    };
    ws.onmessage(event);
  });
  
  ws.send = function(d) {
    socket.write(d);
  }
  ws.close = function() {
    socket.end();
  }
  
  return ws;
}

module.exports = Stomp.Stomp;
module.exports.wrap = wrap;
