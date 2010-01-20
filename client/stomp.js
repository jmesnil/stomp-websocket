
Stomp = function (url){

  debug = function(str) {
    $("#debug").append("<p>"+str+"</p>");
  }

  return {
    ws: null,
    login: null,
    passcode: null,

    connect : function(login, passcode) {
      debug("Opening Web Socket...");
      this.ws = new WebSocket(url);
      this.ws.onmessage = this.onmessage;
      this.ws.onclose   = this.onclose;
      this.ws.onopen    = this.onopen;
      this.login = login;
      this.passcode = passcode;
    },

    onclose: function()
    {
      debug("Whoops! Looks like you lost internet connection or the server went down");
    },

    onopen : function() {
      debug('Web Socket Opened...');
      debug("[CONNECT]: " + login + " " + password);
      // send to the server a CONNECT frame
    },

    disconnect : function()
    {
      debug("[DISCONNECT]");
      // send to the server a DISCONNECT frame
      debug("Disconnecting...");
      this.ws.close();
    },

    onmessage : function(evt) {
      debug('[RECEIVE] ' + evt);
      // next, check what type of message RECEIPT, ERROR, CONNECTED, RECEIVE
      // and create appropriate js objects and calls handler for received messags
      this.receive(evt);
    },

    send : function(headers, body) {
      debug("[SEND] " + headers + " " + body);
      // send to the server
      // dataStr = "...."
      // Stomp.ws.send(dataStr);
    },
  }
};
