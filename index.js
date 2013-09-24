var Stomp = require('./lib/stomp.js');
var StompNode = require('./lib/stomp-node.js');

module.exports = Stomp.Stomp;
module.exports.overTCP = StompNode.overTCP;
module.exports.overWS = StompNode.overWS;