var Stomp = require("./stomp");
var net   = require('net');

var wrap = function(port, host) {
  // node.js net.Socket;
  var socket;

  // Web Socket-like object
  var ws = {
    url: 'tcp:// ' + host + ':' + port,
    send: function(d) {
      socket.write(d);
    },
    close: function() {
      socket.end();
    }
  };

  socket = net.connect(port, host, function(e) {
    ws.onopen();
  });
  socket.on('close', function(e) {
    // handler can be null if the ws is properly closed
    if (ws.onclose) {
      ws.onclose();
    }
  });
  socket.on('data', function(data) {
    // wrap the data in an event object
    var event = {
      'data': data.toString()
    };
    ws.onmessage(event);
  });
  
  return ws;
};

var client = function(host, port) {
  var socket = wrap(port, host);
  return Stomp.Stomp.over(socket);
}

module.exports = Stomp.Stomp;
module.exports.client = client;
