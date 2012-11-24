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
# The library is accessed through the `Stomp` object that is set on the `window`
# when running in a Web browser.

# Define constants for bytes used throughout the code.
Byte =
  # LINEFEED byte (octet 10)
  LF: '\x0A'
  # NULL byte (octet 0)
  NULL: '\x00'

# Representation of a [STOMP frame](http://stomp.github.com/stomp-specification-1.1.html#STOMP_Frames)
class Frame
  # Frame constructor
  constructor: (@command, @headers={}, @body='') ->

  # Provides a textual representation of the frame
  # suitable to be sent to the server
  toString: ->
    lines = [@command]
    for own name, value of @headers
      lines.push("#{name}:#{value}")
    lines.push(Byte.LF + @body)
    return lines.join(Byte.LF)

  # Unmarshall a single STOMP frame from a `data` string
  @_unmarshallSingle: (data) ->
    # search for 2 consecutives LF byte
    divider = data.search(///#{Byte.LF}#{Byte.LF}///)
    headerLines = data.substring(0, divider).split(Byte.LF)
    command = headerLines.shift()
    headers = {}
    # utility function to trim any whitespace before and after a string
    trim= (str) ->
      str.replace(/^\s+|\s+$/g,'')
    # Parse headers
    line = idx = null
    for i in [0...headerLines.length]
      line = headerLines[i]
      idx = line.indexOf(':')
      headers[trim(line.substring(0, idx))] = trim(line.substring(idx + 1))
    # Parse body, stopping at the first \0 found.
    # **TODO** Add support for content-length header.
    body = ''
    chr = null
    for i in [(divider + 2)...data.length]
      chr = data.charAt(i)
      if chr is Byte.NULL
        break
      body += chr
    return new Frame(command, headers, body)

  # Split the data before unmarshalling every single STOMP frame.
  # Web socket servers can send multiple frames in a single websocket message.
  #
  # `datas` is a string.
  @unmarshall: (datas) ->
    # Ugly list comprehension to split and unmarshall *multiple STOMP frames*
    # contained in a *single WebSocket frame*.
    # The data are splitted when a NULL byte (follwode by zero or many LF bytes) is found
    return (Frame._unmarshallSingle(data) for data in datas.split(///#{Byte.NULL}#{Byte.LF}*///) when data?.length > 0)

  # Marshall a Stomp frame
  @marshall: (command, headers, body) ->
    frame = new Frame(command, headers, body)
    return frame.toString() + Byte.NULL

Stomp =

  # Version of the JavaScript library. This can be used to check what has
  # changed in the release notes
  libVersion: "2.0.0"

  VERSIONS:
    V1_0: '1.0'
    V1_1: '1.1'
    V1_2: '1.2'

    # Versions of STOMP specifications supported
    supportedVersions: ->
      '1.1,1.0'

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
      # expect to receive server heartbeat at least every 10s by default
      # (value in ms)
      incoming: 10000
    }
    # subscription callbacks indexed by subscriber's ID
    @subscriptions = {}

  _transmit: (command, headers, body) ->
    out = Frame.marshall(command, headers, body)
    @debug? ">>> " + out
    @ws.send(out)

  _setupHeartbeat: (headers) ->
    if headers.version in [Stomp.VERSIONS.V1_1, Stomp.VERSIONS.V1_2]
      # heart-beat header received from the server looks like:
      #
      #     heart-beat: sx, sy
      [serverOutgoing, serverIncoming] = (parseInt(v) for v in headers['heart-beat'].split(","))

      unless @heartbeat.outgoing == 0 or serverIncoming == 0
        ttl = Math.max(@heartbeat.outgoing, serverIncoming)
        @debug? "send PING every #{ttl}ms"
        @pinger = window?.setInterval(=>
          @ws.send Byte.LF
          @debug? ">>> PING"
        , ttl)

      unless @heartbeat.incoming == 0 or serverOutgoing == 0
        ttl = Math.max(@heartbeat.incoming, serverOutgoing)
        @debug? "check PONG every #{ttl}ms"
        @ponger = window?.setInterval(=>
          delta = Date.now() - @serverActivity
          # We wait twice the TTL to be flexible on window's setInterval calls
          if delta > ttl * 2
            @debug? "did not receive server activity for the last #{delta}ms"
            @_cleanUp()
        , ttl)

  # [CONNECT Frame](http://stomp.github.com/stomp-specification-1.1.html#CONNECT_or_STOMP_Frame)
  connect: (login_,
      passcode_,
      @connectCallback,
      errorCallback,
      vhost_,
      heartbeat="10000,10000") ->
    @debug? "Opening Web Socket..."
    @ws.onmessage = (evt) =>
      data = if typeof(ArrayBuffer) != 'undefined' and evt.data instanceof ArrayBuffer
        view = new Uint8Array( evt.data )
        @debug? "--- got data length: #{view.length}"
        data = ""
        for i in view
          data += String.fromCharCode(i)
        data
      else
        evt.data
      @serverActivity = Date.now()
      if data == Byte.LF # heartbeat
        @debug? "<<< PONG"
        return
      @debug? "<<< #{data}"
      # Handle STOMP frames received from the server
      for frame in Frame.unmarshall(data)
        # [CONNECTED Frame](http://stomp.github.com/stomp-specification-1.1.html#CONNECTED_Frame)
        if frame.command is "CONNECTED"
          @debug? "connected to server #{frame.headers.server}"
          @connected = true
          @_setupHeartbeat(frame.headers)
          @connectCallback? frame
        # [MESSAGE Frame](http://stomp.github.com/stomp-specification-1.1.html#MESSAGE)
        else if frame.command is "MESSAGE"
          # the `onreceive` callback is registered when the client calls `subscribe()`
          onreceive = @subscriptions[frame.headers.subscription]
          onreceive? frame
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
          @debug? "Unhandled frame: #{frame}"
    @ws.onclose   = =>
      msg = "Whoops! Lost connection to #{@ws.url}"
      @debug?(msg)
      errorCallback?(msg)
    @ws.onopen    = =>
      @debug?('Web Socket Opened...')
      headers = {login: login_, passcode: passcode_}
      headers.host = vhost_ if vhost_
      headers['heart-beat'] = heartbeat
      [@heartbeat.outgoing, @heartbeat.incoming] = (parseInt(v) for v in heartbeat.split(","))
      headers['accept-version'] = Stomp.VERSIONS.supportedVersions()
      @_transmit "CONNECT", headers

  # [DISCONNECT Frame](http://stomp.github.com/stomp-specification-1.1.html#DISCONNECT)
  disconnect: (disconnectCallback) ->
    @_transmit "DISCONNECT"
    # Discard the onclose callback to avoid calling the errorCallback when
    # the client is properly disconnected.
    @ws.onclose = null
    @_cleanUp()
    disconnectCallback?()

  # Clean up client resources when it is disconnected or the server did not
  # send heart beats in a timely fashion
  _cleanUp: () ->
    @ws.close()
    @connected = false
    window?.clearInterval(@pinger) if @pinger
    window?.clearInterval(@ponger) if @ponger

  # [SEND Frame](http://stomp.github.com/stomp-specification-1.1.html#SEND)
  send: (destination, headers={}, body='') ->
    headers.destination = destination
    @_transmit "SEND", headers, body

  # [SUBSCRIBE Frame](http://stomp.github.com/stomp-specification-1.1.html#SUBSCRIBE)
  subscribe: (destination, callback, headers={}) ->
    if typeof(headers.id) == 'undefined' || headers.id.length == 0
      id = "sub-" + @counter++
      headers.id = id
    else
      id = headers.id
    headers.destination = destination
    @subscriptions[id] = callback
    @_transmit "SUBSCRIBE", headers
    return id
  
  # [UNSUBSCRIBE Frame](http://stomp.github.com/stomp-specification-1.1.html#UNSUBSCRIBE)
  unsubscribe: (id, headers={}) ->
    headers.id = id
    delete @subscriptions[id]
    @_transmit "UNSUBSCRIBE", headers
  
  # [BEGIN Frame](http://stomp.github.com/stomp-specification-1.1.html#BEGIN)
  begin: (transaction, headers={}) ->
    headers.transaction = transaction
    @_transmit "BEGIN", headers
  
  # [COMMIT Frame](http://stomp.github.com/stomp-specification-1.1.html#COMMIT)
  commit: (transaction, headers={}) ->
    headers.transaction = transaction
    @_transmit "COMMIT", headers
  
  # [ABORT Frame](http://stomp.github.com/stomp-specification-1.1.html#ABORT)
  abort: (transaction, headers={}) ->
    headers.transaction = transaction
    @_transmit "ABORT", headers
  
  # [ACK Frame](http://stomp.github.com/stomp-specification-1.1.html#ACK)
  ack: (message_id, headers={}) ->
    headers["message-id"] = message_id
    @_transmit "ACK", headers

if window?
  window.Stomp = Stomp
else
  # For testing purpose, expose the Frame class inside Stomp to be able to
  # marshall/unmarshall frames
  Stomp.Frame = Frame
  exports.Stomp = Stomp
  Stomp.WebSocketClass = require('./test/server.mock.js').StompServerMock
