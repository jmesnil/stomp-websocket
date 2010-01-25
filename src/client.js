  Stomp.client = function (url){

    var that, ws, login, passcode;

    debug = function(str) {
      if (that.debug) {
        that.debug(str);
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
      debug('<<< ' + evt.data);
      // next, check what type of message RECEIPT, ERROR, CONNECTED, RECEIVE
      // and create appropriate js objects and calls handler for received messags
      // when CONNECTED is received, call onconnect
      // when RECEIVE is received, call onreceive
      // when ERROR is received, call onerror
      // when RECEIPT is received, call onreceipt
      var frame = Stomp.unmarshall(evt.data);
      if (frame.indexOf("CONNECTED") > -1 && that.onconnect) {
      //if (frame.command === "CONNECTED" && that.onconnect) {
        that.onconnect(frame);
      } else if (frame.indexOf("MESSAGE") && that.onreceive) {
      //} else if (frame.command === "MESSAGE" && that.onreceive) {
        that.onreceive(frame);
      } else if (frame.indexOf("RECEIPT") && that.onreceipt) {
      //} else if (frame.command === "RECEIPT" && that.onreceipt) {
        that.onreceipt(frame);
      } else if (frame.indexOf("ERROR") && that.onerror) {
      // } else if (frame.command === "ERROR" && that.onerror) {
        that.onerror(frame);
      }
    };

    transmit = function(command, headers, body) {
      var out = Stomp.marshall(command, headers, body);
      debug(">>> " + out);
      ws.send(out);
    }

    that = {};

    that.connect = function(login_, passcode_) {
      debug("Opening Web Socket...");
      ws = new WebSocket(url);
      ws.onmessage = onmessage;
      ws.onclose   = onclose;
      ws.onopen    = onopen;
      login = login_;
      passcode = passcode_;
    };

    that.disconnect = function() {
      transmit("DISCONNECT");
      // send to the server a DISCONNECT frame
      ws.close();
      if (that.ondisconnect) {
        that.ondisconnect();
      }
    };

    that.send = function(destination, headers, body) {
      headers = headers || {};
      headers.destination = destination;
      transmit("SEND", headers, body);
    };

    that.subscribe = function(destination, ack) {
      var headers = {destination: destination};
      if (ack) {
        headers.ack = ack;
      } else {
        headers.ack = 'auto';
      }
      transmit("SUBSCRIBE", headers);
    };

    that.unsubscribe = function(destination) {
      var headers = {destination: destination};
      transmit("UNSUBSCRIBE", headers);
    };

    // FIXME temporary exposes the handlers to simulate events
    that.onmessage = onmessage;
    that.onopen = onopen;

    return that;
  };

