$(document).ready(function(){

  var url = "ws://localhost:61613/stomp";
  var login = "brianm";
  var passcode = "wombats"
  var destination = "/queue/test";
  
  $("#server_url").text(url);
  $("#queue_name").text(destination);
  
  var client = Stomp.client(url);

  debug = function(str) {
    $("#debug").append(str + "\n");
  };
  client.debug = debug;
  // the client is notified when it is connected to the server.
  client.onconnect = function(frame) {
      debug("connected to Stomp");
      client.subscribe(destination, "auto", {receipt: 123}, function(frame) {
        client.disconnect();
      });
  };
  client.onerror = function(frame) {
      debug("connected to Stomp");
  };
  client.ondisconnect = function() {
    debug("disconnected from Stomp");
  };
  client.onreceipt = function() {
    debug("receipt from Stomp");
    client.send(destination, {foo: 1}, "test")
  };

  client.connect(login, passcode);

  return false;
});
