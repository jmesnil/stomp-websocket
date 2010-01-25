module("Stomp Frame");

test("marshall a CONNECT frame", function() {
  var out = Stomp.marshall("CONNECT", {login: 'jmesnil', passcode: 'wombats'});
  equals(out, "CONNECT\nlogin: jmesnil\npasscode: wombats\n\n\0");
});

test("marshall a SEND frame", function() {
  var out = Stomp.marshall("SEND", {destination: '/queue/test'}, "hello, world!");
  equals(out, "SEND\ndestination: /queue/test\n\nhello, world!\0");
});

test("unmarshall a CONNECTED frame", function() {
  var data = "CONNECTED\nsession-id: 1234\n\n";
  var frame = Stomp.unmarshall(data);
  equals("CONNECTED", frame.command);
  same({'session-id': "1234"}, frame.headers);
  ok(frame.body === undefined);
});

test("unmarshall a RECEIVE frame", function() {
  var data = "RECEIVE\nfoo: abc\nbar: 1234\n\nhello, world!";
  var frame = Stomp.unmarshall(data);
  equals("RECEIVE", frame.command);
  same({foo : 'abc', bar: "1234"}, frame.headers);
  equals("hello, world!", frame.body);
});