module("Stomp Frame");

test("marshal a CONNECT frame", function() {
  var out = Stomp.marshal("CONNECT", {login: 'jmesnil', passcode: 'wombats'});
  equals(out, "CONNECT\nlogin:jmesnil\npasscode:wombats\n\n\0");
});

test("marshal a SEND frame", function() {
  var out = Stomp.marshal("SEND", {destination: '/queue/test'}, "hello, world!");
  equals(out, "SEND\ndestination:/queue/test\n\nhello, world!\0");
});

test("unmarshal a CONNECTED frame", function() {
  var data = "CONNECTED\nsession-id: 1234\n\n\0";
  var frame = Stomp.unmarshal(data);
  equals(frame.command, "CONNECTED");
  same(frame.headers, {'session-id': "1234"});
  equals(frame.body, '');
});

test("unmarshal a RECEIVE frame", function() {
  var data = "RECEIVE\nfoo: abc\nbar: 1234\n\nhello, world!\0";
  var frame = Stomp.unmarshal(data);
  equals(frame.command, "RECEIVE");
  same(frame.headers, {foo: 'abc', bar: "1234"});
  equals(frame.body, "hello, world!");
});

test("unmarshal should not include the null byte in the body", function() {
  var body1 = 'Just the text please.',
      body2 = 'And the newline\n',
      msg = "MESSAGE\ndestination: /queue/test\nmessage-id: 123\n\n";

  equals(Stomp.unmarshal(msg + body1 + '\0').body, body1);
  equals(Stomp.unmarshal(msg + body2 + '\0').body, body2);
});

test("unmarshal should support colons (:) in header values", function() {
  var dest = 'foo:bar:baz',
      msg = "MESSAGE\ndestination: " + dest + "\nmessage-id: 456\n\n\0";

  equals(Stomp.unmarshal(msg).headers.destination, dest);
});
