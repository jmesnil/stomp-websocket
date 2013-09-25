Stomp = require('./stomp')
net   = require('net')

wrapTCP= (port, host) ->
  socket = null

  ws = {
    url: 'tcp:// ' + host + ':' + port
    send: (d) -> socket.write(d)
    close: -> socket.end()
  }

  socket = net.connect port, host, (e) -> ws.onopen()
  socket.on 'error', (e) -> ws.onclose?(e)
  socket.on 'close', (e) -> ws.onclose?(e)
  socket.on 'data', (data) ->
    event = {
      'data': data.toString()
    }
    ws.onmessage(event)

  return ws

wrapWS= (url) ->
  WebSocketClient = require('websocket').client

  connection = null

  ws = {
    url: url
    send: (d) -> connection.sendUTF(d)
    close: ->connection.close()
  }
  
  socket = new WebSocketClient()
  socket.on 'connect', (conn) ->
    connection = conn
    ws.onopen()
    connection.on 'error', (error) -> ws.onclose?(error)
    connection.on 'close', -> ws.onclose?(error)
    connection.on 'message', (message) ->
      if message.type == 'utf8'
        event = {
          'data': message.utf8Data
        }
        ws.onmessage(event)

  socket.connect url
  return ws

overTCP = (host, port) ->
  socket = wrapTCP port, host
  Stomp.Stomp.over socket

overWS = (url) ->
  socket = wrapWS url
  Stomp.Stomp.over socket

exports.overTCP = overTCP
exports.overWS = overWS
