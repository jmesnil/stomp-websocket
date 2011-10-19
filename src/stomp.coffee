Stomp =
  frame: `function(command, headers, body) {
    return {
      command: command,
      headers: headers,
      body: body,
      toString: function() {
        var out = command + '\n';
        if (headers) {
          for (header in headers) {
            if(headers.hasOwnProperty(header)) {
              out = out + header + ': ' + headers[header] + '\n';
            }
          }
        }
        out = out + '\n';
        if (body) {
          out = out + body;
        }
        return out;
      }
    }
  }`
  unmarshal: `function(data) {
    var divider = data.search(/\n\n/),
        headerLines = data.substring(0, divider).split('\n'),
        command = headerLines.shift(),
        headers = {},
        body = '';

    trim = function(str) {
      return str.replace(/^\s+/g,'').replace(/\s+$/g,'');
    };

    // Parse headers
    var line = idx = null;
    for (var i = 0; i < headerLines.length; i++) {
      line = headerLines[i];
      idx = line.indexOf(':');
      headers[trim(line.substring(0, idx))] = trim(line.substring(idx + 1));
    }
    
    // Parse body, stopping at the first \0 found.
    // TODO: Add support for content-length header.
    var chr = null;
    for (var i = divider + 2; i < data.length; i++) {
      chr = data.charAt(i);
      if (chr === '\0') {
         break;
      }
      body += chr;
    }

    return Stomp.frame(command, headers, body);
  }`
  marshal: `function(command, headers, body) {
    return Stomp.frame(command, headers, body).toString() + '\0';
  }`
  client: (url) ->
    new Client url
  
class Client
  constructor: (@url) ->
    # used to index subscribers
    @counter = 0 
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
    @ws.onmessage = (evt) ->
      client.debug?('<<< ' + evt.data)
      frame = Stomp.unmarshal(evt.data)
      if frame.command is "CONNECTED" and client.connectCallback
        client.connectCallback(frame)
      else if frame.command is "MESSAGE"
        onreceive = client.subscriptions[frame.headers.subscription]
        onreceive?(frame)
      else if frame.command is "RECEIPT"
        client.onreceipt?(frame)
      else if frame.command is "ERROR"
        client.onerror?(frame)
    @ws.onclose   = ->
      msg = "Whoops! Lost connection to " + client.url
      client.debug?(msg)
      errorCallback?(msg)
    @ws.onopen    = ->
      client.debug?('Web Socket Opened...')
      client._transmit("CONNECT", {login: login_, passcode: passcode_})
    @login = login_
    @passcode = passcode_
    @connectCallback = connectCallback
  
  disconnect: (disconnectCallback) ->
    @_transmit("DISCONNECT")
    @ws.close()
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