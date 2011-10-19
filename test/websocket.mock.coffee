Event = (type) -> {'type': type}

class WebSocketMock
  constructor: (@url) ->
    @onclose = ->
    @onopen = ->
    @onerror = ->
    @onmessage = ->
    @readyState = 0
    @bufferedAmount = 0
    @extensions = ''
    @protocol = ''
    setTimeout((=> @handle_open()), 0)
  
  # WebSocket API
  
  close: ->
    setTimeout(@handle_close, 0)
    @readyState = 2
   
  send: (msg) ->
    if @readyState isnt 1 then return false
    setTimeout((=> @handle_send(msg)), 0)
    return true
  
  # Helpers
  
  _accept: ->
    @readyState = 1
    @onopen(Event('open'))
  
  _shutdown: ->
    @readyState = 3
    @onclose(Event('close'))
  
  _error: ->
    @readyState = 3
    @onerror(Event('error'))
  
  _respond: (data) ->
    event = Event('message')
    event.data = data
    @onmessage(event)
    
  # Handlers
  
  handle_send: (msg) ->
    # implement me
  
  handle_close: ->
    # implement me
  
  handle_open: ->
    # implement me

exports.WebSocketMock = WebSocketMock