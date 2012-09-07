Stomp = require('../stomp.js').Stomp
StompServerMock = require('./server.mock.js').StompServerMock

describe "Stomp", ->
  it "lets you connect to a server with a websocket and get a callback", ->
    ws = new StompServerMock("ws://mocked/stomp/server")
    client = Stomp.over(ws)
    connected = false
    client.connect("guest", "guest", ->
      connected = true
    )
    waitsFor -> connected
    runs -> expect(client.connected).toBe(true)
  
  it "lets you connect to a server and get a callback", ->
    client = Stomp.client("ws://mocked/stomp/server")
    connected = false
    client.connect("guest", "guest", ->
      connected = true
    )
    waitsFor -> connected
    runs -> expect(client.connected).toBe(true)
  
  it "lets you subscribe to a destination", ->
    client = Stomp.client("ws://mocked/stomp/server")
    id = null
    client.connect("guest", "guest", ->
      id = client.subscribe("/queue/test")
    )
    waitsFor -> id
    runs -> expect(Object.keys(client.ws.subscriptions)).toContain(id)
  
  it "lets you publish a message to a destination", ->
    client = Stomp.client("ws://mocked/stomp/server")
    message = null
    client.connect("guest", "guest", ->
      message = "Hello world!"
      client.send("/queue/test", {}, message)
    )
    waitsFor -> message
    runs -> expect(client.ws.messages).toContain(message)
  
  it "lets you unsubscribe from a destination", ->
    client = Stomp.client("ws://mocked/stomp/server")
    unsubscribed = false
    id = null
    client.connect("guest", "guest", ->
      id = client.subscribe("/queue/test")
      client.unsubscribe(id)
      unsubscribed = true
    )
    waitsFor -> unsubscribed
    runs -> expect(Object.keys(client.ws.subscriptions)).not.toContain(id)
    
  it "lets you receive messages only while subscribed", ->
    client = Stomp.client("ws://mocked/stomp/server")
    id = null
    messages = []
    client.connect("guest", "guest", ->
      id = client.subscribe("/queue/test", (msg) ->
        messages.push(msg)
      )
    )
    waitsFor -> id
    runs ->
      client.ws.test_send(id, Math.random())
      client.ws.test_send(id, Math.random())
      expect(messages.length).toEqual(2)
      client.unsubscribe(id)
      try
        client.ws.test_send(id, Math.random()) 
      catch err
        null
      expect(messages.length).toEqual(2)
  
  it "lets you ack messages received from subscriptions set up for acking", ->
    # id = client.subscribe(
    #   "/queue/test"
    #   (message) ->
    #     message_id = message.headers['message-id']
    #     client.ack(message_id)
    #   {ack: 'client'}
    # )
  
  it "lets you send messages in a transaction", ->
    client = Stomp.client("ws://mocked/stomp/server")
    connected = false
    client.connect("guest", "guest", ->
      connected = true
    )
    waitsFor -> connected
    runs ->
      txid = "123"
      client.begin(txid)
      client.send("/queue/test", {transaction: txid}, "messages 1")
      client.send("/queue/test", {transaction: txid}, "messages 2")
      expect(client.ws.messages.length).toEqual(0)
      client.send("/queue/test", {transaction: txid}, "messages 3")
      client.commit(txid)
      expect(client.ws.messages.length).toEqual(3)
  
  it "lets you abort a transaction", ->
    client = Stomp.client("ws://mocked/stomp/server")
    connected = false
    client.connect("guest", "guest", ->
      connected = true
    )
    waitsFor -> connected
    runs ->
      txid = "123"
      client.begin(txid)
      client.send("/queue/test", {transaction: txid}, "messages 1")
      client.send("/queue/test", {transaction: txid}, "messages 2")
      expect(client.ws.messages.length).toEqual(0)
      client.send("/queue/test", {transaction: txid}, "messages 3")
      client.abort(txid)
      expect(client.ws.messages.length).toEqual(0)