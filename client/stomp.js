// client can implement the eventhandlers:
// * onconnect    => to be notified when it is connected to the STOMP server
// * ondisconnect => to be notified when it is disconnected from the STOMP server
// * onreceive    => to receive STOMP messages
// * onreceipt    => to receive STOMP receipts
// * onerror      => to receive STOMP errors

var stomp = function (url){

  var client, ws, login, passcode;
  
  debug = function(str) {
    $("#debug").append("<p>"+str+"</p>");
  }

  onclose = function()
  {
    debug("Whoops! Looks like you lost internet connection or the server went down");
  };

  onopen = function() {
    debug('Web Socket Opened...');
    debug("[CONNECT]: " + login + " " + passcode);
    // send to the server a CONNECT frame
    // FIXME this should go in onmessage when receiving a CONNECTED:
    if (client.onconnect) {
      client.onconnect();
    }
  };

  onmessage = function(evt) {
    debug('[RECEIVE] ' + evt);
    // next, check what type of message RECEIPT, ERROR, CONNECTED, RECEIVE
    // and create appropriate js objects and calls handler for received messags
    // when CONNECTED is received, call onconnect
    // when RECEIVE is received, call onreceive
    // when ERROR is received, call onerror
    // when RECEIPT is received, call onreceipt
    if (client.onreceive) {
      client.onreceive(evt);
    }
  };

  client = {};

  client.connect = function(login_, passcode_) {
    debug("Opening Web Socket...");
    ws = new WebSocket(url);
    ws.onmessage = onmessage;
    ws.onclose   = onclose;
    ws.onopen    = onopen;
    login = login_;
    passcode = passcode_;
  };

  client.disconnect = function() {
    debug("[DISCONNECT]");
    // send to the server a DISCONNECT frame
    debug("Disconnecting...");
    ws.close();
    if (client.ondisconnect) {
      client.ondisconnect();
    }
  };

  client.send = function(headers, body) {
    debug("[SEND] " + headers + " " + body);
    // send to the server
    // dataStr = "...."
    // Stomp.ws.send(dataStr);
  };

  client.subscribe = function(destination, ack) {
    debug("[SUBSCRIBE] " + destination + " " + ack);
    // send to the server a SUBSCRIBE frame
  };

  client.unsubscribe = function(destination) {
    debug("[UNSUBSCRIBE] " + destination);
    // send to the server a UNSUBSCRIBE frame
  };

  // FIXME temporary exposes the handlers to simulate events
  client.onmessage = onmessage;
  client.onopen = onopen;

  return client;
};
