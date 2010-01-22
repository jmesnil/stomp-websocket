module("Stomp Frame");

test("marshall a CONNECT frame", function() {
  //FIXME how can I have frame without creating stomp first?
  stomp("foo");

  out = marshall("CONNECT", {login: 'jmesnil', passcode: 'wombats'});
  equals(out, "CONNECT\nlogin: jmesnil\npasscode: wombats\n\n\0");
});

test("marshall a SEND frame", function() {
  //FIXME how can I have frame without creating stomp first?
  stomp("foo");

  out = marshall("SEND", {destination: '/queue/test'}, "hello, world!");
  equals(out, "SEND\ndestination: /queue/test\n\nhello, world!\0");
});
