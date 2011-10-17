module("Stomp Transaction");

test("Send a message in a transaction and abort", function() {
  
  var txid = "txid_" + Math.random();
  var body = Math.random();
  var body2 = Math.random();
  
  var client = Stomp.client(TEST.url);
  
  client.debug = TEST.debug;
  client.connect(TEST.login, TEST.password,
    function() {
      client.subscribe(TEST.destination, function(message)
      {
        start();
        // we should receive the 2nd message outside the transaction
        equals(message.body, body2);
        client.disconnect();
      });
      
      client.begin(txid);
      client.send(TEST.destination, {transaction: txid}, body);
      client.abort(txid);
      client.send(TEST.destination, {}, body2);
    });
    stop(TEST.timeout);
});

test("Send a message in a transaction and commit", function() {
  
  var txid = "txid_" + Math.random();
  var body = Math.random();
  
  var client = Stomp.client(TEST.url);
  
  client.debug = TEST.debug;
  client.connect(TEST.login, TEST.password,
    function() {
      client.subscribe(TEST.destination, function(message)
      {
        start();
        equals(message.body, body);
        client.disconnect();
      });
      client.begin(txid);
      client.send(TEST.destination, {transaction: txid}, body);
      client.commit(txid);
    });
    stop(TEST.timeout);
});
