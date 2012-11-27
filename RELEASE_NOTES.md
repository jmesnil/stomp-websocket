# Release Notes

## 2.0 (Date TBD)

### STOMP 1.1 support

* heart-beat
* nack
* content-length

### API change

* `connect()` method takes an additional `heartbeat` parameter which is a string of the form `"cx, cy"` expected by the [`heart-beat`](http://stomp.github.com/stomp-specification-1.1.html#Heart-beating) header of the CONNECT frame. 

* the `errorCallback` passed to the `connect()` method is no longer called when the
  client is properly disconnected by calling `disconnect()`.

* ack() method takes 3 parameters:
  * `messageID` & `subscription` are MANDATORY.
  * `transaction` is OPTIONAL.

* the `client` object has a `heartbeat` field which can be used to configure heart-beating by changing its `incoming` and `outgoing` integer fields (default value for both is 10000ms):

    client.heartbeat.outgoing = 20000 // client will send heartbeats every 20000ms
    client.heartbeat.incoming = 0 // client does not want to receive heartbeats
                                                   // from the server

### Minified version

In addition to the regular `stomp.js` file, the library is also available in a minified version `stomp.min.js`

### Annotated source

The source is now [documented](http://jmesnil.net/stomp-websocket/stomp.html) :)
