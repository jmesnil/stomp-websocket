
  var stomp = function (url){

    var client, ws, login, passcode;

    debug = function(str) {
      if (client.debug) {
        client.debug(str);
      }
    };

    onclose = function() {
      debug("Whoops! Looks like you lost internet connection or the server went down");
    };

    onopen = function() {
      debug('Web Socket Opened...');
      transmit("CONNECT", {login: login, passcode: passcode});
      // onconnect handler will be called from onmessage when a CONNECTED frame is received
    };

    onmessage = function(evt) {
      debug('<<< ' + evt);
      // next, check what type of message RECEIPT, ERROR, CONNECTED, RECEIVE
      // and create appropriate js objects and calls handler for received messags
      // when CONNECTED is received, call onconnect
      // when RECEIVE is received, call onreceive
      // when ERROR is received, call onerror
      // when RECEIPT is received, call onreceipt
      frame = unmarshall(evt);
      if (frame.command === "CONNECTED" && client.onconnect) {
        client.onconnect(frame);
      } else if (frame.command === "MESSAGE" && client.onreceive) {
        client.onreceive(frame);
      } else if (frame.command === "RECEIPT" && client.onreceipt) {
        client.onreceipt(frame);
      } else if (frame.command === "ERROR" && client.onerror) {
        client.onerror(frame);
      }
    };

    transmit = function(command, headers, body) {
      out = marshall(command, headers, body);
      debug(">>> " + out);
      //ws.send(out);
    }

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
      transmit("DISCONNECT");
      // send to the server a DISCONNECT frame
      ws.close();
      if (client.ondisconnect) {
        client.ondisconnect();
      }
    };

    client.send = function(destination, headers, body) {
      headers.destination = destination;
      transmit("SEND", headers, body);
    };

    client.subscribe = function(destination, ack) {
      headers = {destination: destination};
      if (ack) {
        headers.ack = ack;
      } else {
        headers.ack = 'auto';
      }
      transmit("SUBSCRIBE", headers);
    };

    client.unsubscribe = function(destination) {
      headers = {destination: destination};
      transmit("UNSUBSCRIBE", headers);
    };

    // FIXME temporary exposes the handlers to simulate events
    client.onmessage = onmessage;
    client.onopen = onopen;

    return client;
  };

