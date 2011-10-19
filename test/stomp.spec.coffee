Stomp = require('../stomp.js').Stomp

describe "Stomp", ->
  it "lets you follow the documentation", ->
    # Create a Stomp client
    url = "ws://localhost:9000/stomp"
    client = Stomp.client(url);
    
    # Connection to the server
    error_callback = (error) ->
      expect(error.headers.message).toBeDefined()
    connect_callback = ->
      
    client.connect("guest", "guest", connect_callback, error_callback)
    
    # Send messages
    client.send("/queue/test", {priority: 9}, "Hello, Stomp")
    
    # Subscribe and receive messages
    messages = []
    callback = (message) ->
      messages.push(message)
    headers = {ack: 'client', 'selector': "location = 'Europe'"}
    id = client.subscribe("/queue/test", callback, headers)

    waitsFor ->
      messages.length > 0
    
    client.unsubscribe(id)
    
    # Acknowledgment
    id = client.subscribe(
      "/queue/test"
      (message) ->
        message_id = message.headers['message-id']
        client.ack(message_id)
      {ack: 'client'}
    )
    client.unsubscribe(id)
      
    # Transactions
    txid = "123"
    client.begin(txid)
    client.send("/queue/test", {transaction: txid}, "message in a transaction")
    client.commit(txid)
    
    # Disconnect
    client.disconnect()