module("Stomp Frame");

test("marshall a CONNECT frame", function() {
  //FIXME how can I have frame without creating stomp first?
  stomp("foo");

  frame = new Frame("CONNECT", {login: 'jmesnil', passcode: 'wombats'});
  
  out = marshall(frame.command, frame.headers, frame.body);
  equals(out, "CONNECT\nlogin: jmesnil\npasscode: wombats\n\n\0");
});
