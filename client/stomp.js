// client can implement the eventhandlers:
// * onconnect    => to be notified when it is connected to the STOMP server
// * ondisconnect => to be notified when it is disconnected from the STOMP server
// * onreceive    => to receive STOMP messages
// * onreceipt    => to receive STOMP receipts
// * onerror      => to receive STOMP errors
//
// client can also define a debug(str) handler to display debug infos

(function(window) {

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
      transmit("CONNECT", {'login': login, 'passcode': passcode});
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

    transmit = function(command, headers, body) {
      frame = command + '\n';
      for (header in headers) {
        if(headers.hasOwnProperty(header)) {
          frame = frame + header + ': ' + headers[header] + '\n';
        }
      }
      frame = frame + '\n';
      if (body) {
        frame = frame + body;
      }
      frame = frame + '\0';
      debug(">>> " + frame);
      //ws.send(frame);
    }

    Frame = function(command, headers, body) {
      this.command = command;
      this.headers = headers;
      this.body = body;
      this.toString = function() {
        frame = command + '\n';
        for (header in headers) {
          if(headers.hasOwnProperty(header)) {
            frame = frame + header + ': ' + headers[header] + '\n';
          }
        }
        frame = frame + '\n';
        if (body) {
          frame = frame + body;
        }
        return frame;
      };
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
      headers = {'destination': destination};
      if (ack) {
        headers.ack = ack;
      } else {
        headers.ack = 'auto';
      }
      transmit("SUBSCRIBE", headers);
    };

    client.unsubscribe = function(destination) {
      headers = {'destination': destination};
      transmit("UNSUBSCRIBE", headers);
    };

    // FIXME temporary exposes the handlers to simulate events
    client.onmessage = onmessage;
    client.onopen = onopen;

    return client;
  };

  window.stomp = stomp;

})(window);
