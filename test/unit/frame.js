module("Stomp Frame");

test("create a CONNECT frame", function() {
  //FIXME how can I have frame without creating stomp first?
  stomp("foo");

  frame = new Frame("CONNECT", {login: 'jmesnil', passcode: 'wombats'});
  equals( "CONNECT", frame.command);
  same({login: 'jmesnil', passcode: 'wombats'}, frame.headers);
  ok(frame.body === undefined);
});
