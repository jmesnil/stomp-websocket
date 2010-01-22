module("Stomp Frame");

test("marshall a CONNECT frame", function() {
  out = Stomp.marshall("CONNECT", {login: 'jmesnil', passcode: 'wombats'});
  equals(out, "CONNECT\nlogin: jmesnil\npasscode: wombats\n\n\0");
});

test("marshall a SEND frame", function() {
  out = Stomp.marshall("SEND", {destination: '/queue/test'}, "hello, world!");
  equals(out, "SEND\ndestination: /queue/test\n\nhello, world!\0");
});
