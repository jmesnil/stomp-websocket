var Stomp = require('./stomp-node');
Stomp.debug = console.log;

var login = 'user';
var passcode = 'password';
var destination = '/queue/myqueue'
var body = 'Hello, node.js!';

// set to false to use Web Sockets
var useTCP = false;

var client;

if (useTCP) {
  // Use raw TCP sockets
  console.log('connect to STOMP over TCP sockets');
  client = Stomp.overTCP('localhost', 61613);
} else { 
  console.log('connect to STOMP over Web sockets');
  client = Stomp.overWS('ws://localhost:61614');
}

// heart-beating is not working yet
client.heartbeat.outgoing = 0;
client.heartbeat.incoming = 0;

client.connect(login, passcode, function(frame) {
  console.log('connected to Stomp');
  
  console.log('subscribing to destination' + destination);
  var subid = client.subscribe(destination, function(message) {
    console.log("received message " + message.body);

    // once we get a message, the client disconnects
    client.disconnect();
  });
  
  console.log('sending message ' + body + ' to ' + destination);
  client.send(destination, {}, body);
});
