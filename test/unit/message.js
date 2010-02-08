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

test("Send and receive a message with a JSON body", function() {
  
  var client = Stomp.client(TEST.url);
  var payload = {text: "hello", bool: true, value: 1.234};
  
  client.connect(TEST.login, TEST.password,
    function() {
      client.subscribe(TEST.destination, function(message)
      {
        start();
        var res = JSON.parse(message.body);
        equals(res.text, payload.text);
        equals(res.bool, payload.bool);
        equals(res.value, payload.value);
        client.disconnect();
      });
      
      client.send(TEST.destination, {}, JSON.stringify(payload));
    });
    stop(TEST.timeout);
});