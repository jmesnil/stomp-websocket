module("Web Sockets");

test("check Web Sockets support", function() {
  if ("MozWebSocket" in window) {
    ok(MozWebSocket, "Firefox supports Web Sockets");
  } else {
    ok(WebSocket, "this browser supports Web Sockets");
  }
});
