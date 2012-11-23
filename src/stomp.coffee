# **STOMP Over Web Socket** is a JavaScript STOMP Client using
# [HTML5 Web Sockets API](http://www.w3.org/TR/websockets).
#
# * Copyright (C) 2010-2012 [Jeff Mesnil](http://jmesnil.net/)
# * Copyright (C) 2012 [FuseSource, Inc.](http://fusesource.com)
#
# This library supports:
#
# * [STOMP 1.0](http://stomp.github.com/stomp-specification-1.0.html)
# * [STOMP 1.1](http://stomp.github.com/stomp-specification-1.1.html)
#
# The library is accessed through this Stomp object.
Stomp =

  HEADERS:
    HOST: 'host'
    ACCEPT_VERSION: 'accept-version'
    VERSION: 'version'
    HEART_BEAT: 'heart-beat'

  VERSIONS:
    VERSION_1_0: '1.0'
    VERSION_1_1: '1.1'
    VERSION_1_2: '1.2'

    # Versions of STOMP specifications supported
    supportedVersions: ->
      '1.1,1.0'

  # Representation of a [STOMP frame](http://stomp.github.com/stomp-specification-1.1.html#STOMP_Frames)
  frame: (command, headers=[], body='') ->
    command: command
    headers: headers
    body: body
    # **FIXME** all these fields should be discarded
    # (but it may break compatibility)
    id: headers.id
    receipt: headers.receipt
    transaction: headers.transaction
    destination: headers.destination
    subscription: headers.subscription
    error: null
    # Provides a textual representation of the frame
    # suitable to be sent to the server
    toString: ->
      lines = [command]
      for own name, value of headers
        lines.push("#{name}:#{value}")
      lines.push('\n'+body)
      return lines.join('\n')
  
  # Unmarshall a single frame from a `data` string
  unmarshal: (data) ->
    divider = data.search(/\n\n/)
    headerLines = data.substring(0, divider).split('\n')
    command = headerLines.shift()
    headers = {}
    body = ''
    # utility function to trim any whitespace from a string
    trim = (str) ->
      str.replace(/^\s+/g,'').replace(/\s+$/g,'')

    # Parse headers
    line = idx = null
    for i in [0...headerLines.length]
      line = headerLines[i]
      idx = line.indexOf(':')
      headers[trim(line.substring(0, idx))] = trim(line.substring(idx + 1))
    
    # Parse body, stopping at the first \0 found.
    # **TODO** Add support for content-length header.
    chr = null
    for i in [(divider + 2)...data.length]
      chr = data.charAt(i)
      if chr is '\x00'
        break
      body += chr

    return Stomp.frame(command, headers, body)

  # Split the data before unmarshalling every single STOMP frame.
  # Web socket servers can send multiple frames in a single websocket message.
  #
  # `multi_datas is a string`.
  unmarshal_multi: (multi_datas) ->
    # Ugly list comprehension to split and unmarshall *multiple STOMP frames*
    # contained in a *single WebSocket frame*.
    datas = (Stomp.unmarshal(data) for data in multi_datas.split(/\x00\n*/) when data && data.length > 0)
    return datas

  # Marshall a Stomp frame
  marshal: (command, headers, body) ->
    Stomp.frame(command, headers, body).toString() + '\x00'

  # This method creates a WebSocket client that is connected to
  # the STOMP server located at the url.
  client: (url, protocols = 'v10.stomp,v11.stomp') ->
    # This is a hack to allow another implementation than the standard
    # HTML5 WebSocket class.
    #
    # It is possible to use another class by calling
    #
    #     Stomp.WebSocketClass = MozWebSocket
    #
    # *prior* to call `Stomp.client()`.
    #
    # This hack is deprecated and  `Stomp.over()` method should be used
    # instead.
    klass = Stomp.WebSocketClass || WebSocket
    ws = new klass(url, protocols)
    new Client ws

  # This method is an alternative to `Stomp.client()` to let the user
  # specify the WebSocket to use (either a standard HTML5 WebSocket or
  # a similar object).
  over: (ws) ->
    new Client ws

# This class represent the STOMP client.
#
# All STOMP protocol is exposed as methods of this class (`connect()`,
# `send()`, etc.)
#
# For debugging purpose, it is possible to set a `debug(message)` method
# on a client instance to receive debug messages (including the actual
# transmission of the STOMP frames over the WebSocket:
#
#     client.debug = function(str) {
#         // append the debug log to a #debug div
#         $("#debug").append(str + "\n");
#     };
class Client
  constructor: (@ws) ->
    @ws.binaryType = "arraybuffer"
    # used to index subscribers
    @counter = 0
    @connected = false
    # Heartbeat properties of the client
    @heartbeat = {
      # send heartbeat every 10s by default (value is in ms)
      outgoing: 10000
      # do not want to receive heartbeats (for now...)
      # **TODO** support server heartbeat to detect stale server
      incoming: 0
    }
    # subscription callbacks indexed by subscriber's ID
    @subscriptions = {}

  _transmit: (command, headers, body) ->
    out = Stomp.marshal(command, headers, body)
    @debug?(">>> " + out)
    @ws.send(out)

  _setupHeartbeat: (headers) ->
    serverVersion = headers[Stomp.HEADERS.VERSION]
    if serverVersion == Stomp.VERSIONS.VERSION_1_1 or
        serverVersion == Stomp.VERSIONS.VERSION_1_2
      [serverOutgoing, serverIncoming] = headers[Stomp.HEADERS.HEART_BEAT].split(",")
      # **TODO** close the connection if the server does not send heart beat (sx, cy)
      serverIncoming = parseInt(serverIncoming)
      unless @heartbeat.outgoing == 0 or serverIncoming == 0
        ttl = Math.max(@heartbeat.outgoing, serverIncoming)
        @debug?("send ping every " + ttl + "ms")
        self = this
        ping = () ->
          self.ws.send('\x0A')
        @pinger = window?.setInterval(ping, ttl)

  # [CONNECT Frame](http://stomp.github.com/stomp-specification-1.1.html#CONNECT_or_STOMP_Frame)
  connect: (login_,
      passcode_,
      connectCallback,
      errorCallback,
      vhost_,
      heartbeat="10000,0") ->
    @debug?("Opening Web Socket...")
    @ws.onmessage = (evt) =>
      data = if typeof(ArrayBuffer) != 'undefined' and evt.data instanceof ArrayBuffer
        view = new Uint8Array( evt.data )
        @debug?('--- got data length: ' + view.length)
        data = ""
        for i in view
          data += String.fromCharCode(i)
        data
      else
        evt.data
      return if data == '\x0A' # heart beat
      @debug?('<<< ' + data)
      # Handle STOMP frames received from the server
      for frame in Stomp.unmarshal_multi(data)
        # [CONNECTED Frame](http://stomp.github.com/stomp-specification-1.1.html#CONNECTED_Frame)
        if frame.command is "CONNECTED" and connectCallback
          @connected = true
          @_setupHeartbeat(frame.headers)
          connectCallback(frame)
        # [MESSAGE Frame](http://stomp.github.com/stomp-specification-1.1.html#MESSAGE)
        else if frame.command is "MESSAGE"
          # the `onreceive` callback is registered when the client calls `subscribe()`
          onreceive = @subscriptions[frame.headers.subscription]
          onreceive?(frame)
        # [RECEIPT Frame](http://stomp.github.com/stomp-specification-1.1.html#RECEIPT)
        #
        # The client instance can set its `onreceipt` field to a function taking
        # a frame argument that will be called when a receipt is received from
        # the server:
        #
        #     client.onreceipt = function(frame) {
        #       receiptID = frame.headers['receipt-id'];
        #       ...
        #     }
        else if frame.command is "RECEIPT"
          @onreceipt?(frame)
        # [ERROR Frame](http://stomp.github.com/stomp-specification-1.1.html#ERROR)
        else if frame.command is "ERROR"
          errorCallback?(frame)
        else
          @debug?("Unhandled frame: " + JSON.stringify(frame))
    @ws.onclose   = =>
      msg = "Whoops! Lost connection to " + @url
      @debug?(msg)
      errorCallback?(msg)
    @ws.onopen    = =>
      @debug?('Web Socket Opened...')
      headers = {login: login_, passcode: passcode_}
      headers[Stomp.HEADERS.HOST] = vhost_ if vhost_
      headers[Stomp.HEADERS.HEART_BEAT] = heartbeat
      [cx, cy] = heartbeat.split(",")
      @heartbeat.outgoing = parseInt(cx)
      @heartbeat.incoming = parseInt(cy)
      headers[Stomp.HEADERS.ACCEPT_VERSION] = Stomp.VERSIONS.supportedVersions()
      @_transmit("CONNECT", headers)
    @connectCallback = connectCallback
  
  # [DISCONNECT Frame](http://stomp.github.com/stomp-specification-1.1.html#DISCONNECT)
  disconnect: (disconnectCallback) ->
    @_transmit("DISCONNECT")
    @ws.close()
    @connected = false
    window?.clearInterval(@pinger) if @pinger
    disconnectCallback?()
  
  # [SEND Frame](http://stomp.github.com/stomp-specification-1.1.html#SEND)
  send: (destination, headers={}, body='') ->
    headers.destination = destination
    @_transmit("SEND", headers, body)
  
  # [SUBSCRIBE Frame](http://stomp.github.com/stomp-specification-1.1.html#SUBSCRIBE)
  subscribe: (destination, callback, headers={}) ->
    if typeof(headers.id) == 'undefined' || headers.id.length == 0
      id = "sub-" + @counter++
      headers.id = id
    else
      id = headers.id
    headers.destination = destination
    @subscriptions[id] = callback
    @_transmit("SUBSCRIBE", headers)
    return id
  
  # [UNSUBSCRIBE Frame](http://stomp.github.com/stomp-specification-1.1.html#UNSUBSCRIBE)
  unsubscribe: (id, headers={}) ->
    headers.id = id
    delete @subscriptions[id]
    @_transmit("UNSUBSCRIBE", headers)
  
  # [BEGIN Frame](http://stomp.github.com/stomp-specification-1.1.html#BEGIN)
  begin: (transaction, headers={}) ->
    headers.transaction = transaction
    @_transmit("BEGIN", headers)
  
  # [COMMIT Frame](http://stomp.github.com/stomp-specification-1.1.html#COMMIT)
  commit: (transaction, headers={}) ->
    headers.transaction = transaction
    @_transmit("COMMIT", headers)
  
  # [ABORT Frame](http://stomp.github.com/stomp-specification-1.1.html#ABORT)
  abort: (transaction, headers={}) ->
    headers.transaction = transaction
    @_transmit("ABORT", headers)
  
  # [ACK Frame](http://stomp.github.com/stomp-specification-1.1.html#ACK)
  ack: (message_id, headers={}) ->
    headers["message-id"] = message_id
    @_transmit("ACK", headers)

if window?
  window.Stomp = Stomp
else
  exports.Stomp = Stomp
  Stomp.WebSocketClass = require('./test/server.mock.js').StompServerMock
