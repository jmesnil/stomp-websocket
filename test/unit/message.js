module("Stomp Message");

test("Send and receive a message", function() {
  
  var client = Stomp.client(TEST.url);
  client.debug = TEST.debug;
  client.connect(TEST.login, TEST.password,
    function() {
      client.subscribe(TEST.destination, function(message)
      {
        start();
        equals(message.body, "message body");
        client.disconnect();
      });
      
      client.send(TEST.destination, {}, "message body");
    });
    stop(TEST.timeout);
});
