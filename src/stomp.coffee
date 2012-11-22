###
Copyright (C) 2010 Jeff Mesnil -- http://jmesnil.net/
Copyright (C) 2012 FuseSource, Inc. -- http://fusesource.com
###

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

    supportedVersions: ->
      '1.1,1.0'

  frame: (command, headers=[], body='') ->
    command: command
    headers: headers
    body: body
    id: headers.id
    receipt: headers.receipt
    transaction: headers.transaction
    destination: headers.destination
    subscription: headers.subscription
    error: null
    toString: ->
      lines = [command]
      for own name, value of headers
        lines.push("#{name}:#{value}")
      lines.push('\n'+body)
      return lines.join('\n')
  
  # unmarshall a single frame
  unmarshal: (data) ->
    divider = data.search(/\n\n/)
    headerLines = data.substring(0, divider).split('\n')
    command = headerLines.shift()
    headers = {}
    body = ''
    trim = (str) ->
      str.replace(/^\s+/g,'').replace(/\s+$/g,'')

    # Parse headers
    line = idx = null
    for i in [0...headerLines.length]
      line = headerLines[i]
      idx = line.indexOf(':')
      headers[trim(line.substring(0, idx))] = trim(line.substring(idx + 1))
    
    # Parse body, stopping at the first \0 found.
    # TODO: Add support for content-length header.
    chr = null
    for i in [(divider + 2)...data.length]
      chr = data.charAt(i)
      if chr is '\x00'
        break
      body += chr

    return Stomp.frame(command, headers, body)

  # Web socket servers can send multiple frames in a single websocket message.
  # Split the data before unmarshalling every single STOMP frame
  unmarshal_multi: (multi_datas) ->
    datas = (Stomp.unmarshal(data) for data in multi_datas.split(/\x00\n*/) when data && data.length > 0)
    return datas

  marshal: (command, headers, body) ->
    Stomp.frame(command, headers, body).toString() + '\x00'
  
  client: (url, protocols = 'v10.stomp') ->
    klass = Stomp.WebSocketClass || WebSocket
    ws = new klass(url, protocols)
    new Client ws

  over: (ws) ->
    new Client ws
  
class Client
  constructor: (@ws) ->
    @ws.binaryType = "arraybuffer"
    # used to index subscribers
    @counter = 0
    @connected = false
    @heartbeat = {
      # send heartbeat every 10s
      outgoing: 10000
      # do not want to receive heartbeats (for now...)
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
      # TODO close the connection if the server does not send heart beat (sx, cy)
      serverIncoming = parseInt(serverIncoming)
      unless @heartbeat.outgoing == 0 or serverIncoming == 0
        ttl = Math.max(@heartbeat.outgoing, serverIncoming)
        @debug?("send ping every " + ttl + "ms")
        self = this
        ping = () ->
          self.ws.send('\x0A')
        @pinger = window?.setInterval(ping, ttl)

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
      for frame in Stomp.unmarshal_multi(data)
        if frame.command is "CONNECTED" and connectCallback
          @connected = true
          @_setupHeartbeat(frame.headers)
          connectCallback(frame)
        else if frame.command is "MESSAGE"
          onreceive = @subscriptions[frame.headers.subscription]
          onreceive?(frame)
        #else if frame.command is "RECEIPT"
        #  @onreceipt?(frame)
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
  
  disconnect: (disconnectCallback) ->
    @_transmit("DISCONNECT")
    @ws.close()
    @connected = false
    window?.clearInterval(@pinger) if @pinger
    disconnectCallback?()
  
  send: (destination, headers={}, body='') ->
    headers.destination = destination
    @_transmit("SEND", headers, body)
  
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
  
  unsubscribe: (id, headers={}) ->
    headers.id = id
    delete @subscriptions[id]
    @_transmit("UNSUBSCRIBE", headers)
  
  begin: (transaction, headers={}) ->
    headers.transaction = transaction
    @_transmit("BEGIN", headers)
  
  commit: (transaction, headers={}) ->
    headers.transaction = transaction
    @_transmit("COMMIT", headers)
  
  abort: (transaction, headers={}) ->
    headers.transaction = transaction
    @_transmit("ABORT", headers)
  
  ack: (message_id, headers={}) ->
    headers["message-id"] = message_id
    @_transmit("ACK", headers)

if window?
  window.Stomp = Stomp
else
  exports.Stomp = Stomp
  Stomp.WebSocketClass = require('./test/server.mock.js').StompServerMock
