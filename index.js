# * Copyright (C) 2013 [Jeff Mesnil](http://jmesnil.net/)
#
# The library can be used in node.js app to connect to STOMP brokers over TCP 
# or Web sockets.

###
   Stomp Over WebSocket http://www.jmesnil.net/stomp-websocket/doc/ | Apache License V2.0

   Copyright (C) 2013 [Jeff Mesnil](http://jmesnil.net/)
###

# Root of the `stompjs module`

var Stomp = require('./lib/stomp.js');
var StompNode = require('./lib/stomp-node.js');

module.exports = Stomp.Stomp;
module.exports.overTCP = StompNode.overTCP;
module.exports.overWS = StompNode.overWS;