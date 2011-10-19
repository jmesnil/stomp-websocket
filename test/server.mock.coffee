WebSocketMock = require('./websocket.mock.js').WebSocketMock

class StompServerMock extends WebSocketMock
  handle_send: (msg) =>
    @_respond(msg)
  
  handle_close: =>
    @_shutdown()
  
  handle_open: =>
    @_accept()

exports.StompServerMock = StompServerMock