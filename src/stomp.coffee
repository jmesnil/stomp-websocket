Stomp =
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
        lines.push("#{name}: #{value}")
      lines.push('\n'+body)
      return lines.join('\n')
  
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
    chr = null;
    for i in [(divider + 2)...data.length]
      chr = data.charAt(i)
      if chr is '\0'
         break
      body += chr

    return Stomp.frame(command, headers, body)
  
  marshal: (command, headers, body) ->
    Stomp.frame(command, headers, body).toString() + '\0'
  
  client: (url) ->
    new Client url
  
class Client
  constructor: (@url) ->
    # used to index subscribers
    @counter = 0 
    @connected = false
    # subscription callbacks indexed by subscriber's ID
    @subscriptions = {};
  
  _transmit: (command, headers, body) ->
    out = Stomp.marshal(command, headers, body)
    @debug?(">>> " + out)
    @ws.send(out)
  
  connect: (login_, passcode_, connectCallback, errorCallback) ->
    client = this
    @debug?("Opening Web Socket...")
    @ws = new WebSocket(@url)
    @ws.onmessage = (evt) =>
      @debug?('<<< ' + evt.data)
      frame = Stomp.unmarshal(evt.data)
      if frame.command is "CONNECTED" and connectCallback
        @connected = true
        connectCallback(frame)
      else if frame.command is "MESSAGE"
        onreceive = @subscriptions[frame.headers.subscription]
        onreceive?(frame)
      #else if frame.command is "RECEIPT"
      #  @onreceipt?(frame)
      #else if frame.command is "ERROR"
      #  @onerror?(frame)
    @ws.onclose   = =>
      msg = "Whoops! Lost connection to " + client.url
      @debug?(msg)
      errorCallback?(msg)
    @ws.onopen    = =>
      @debug?('Web Socket Opened...')
      @_transmit("CONNECT", {login: login_, passcode: passcode_})
    @connectCallback = connectCallback
  
  disconnect: (disconnectCallback) ->
    @_transmit("DISCONNECT")
    @ws.close()
    @connected = false
    disconnectCallback?()
  
  send: (destination, headers={}, body='') ->
    headers.destination = destination
    @_transmit("SEND", headers, body)
  
  subscribe: (destination, callback, headers={}) ->
    id = "sub-" + @counter++
    headers.destination = destination
    headers.id = id
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
  WebSocket = require('./test/server.mock.js').StompServerMock