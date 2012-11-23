# Release Notes

## 2.0 (Date TBD)

### STOMP 1.1 support

* heart-beat

### API change

* `connect()` method takes an additional `heartbeat` parameter which is a string of the form `"cx, cy"` expected by the [`heart-beat`](http://stomp.github.com/stomp-specification-1.1.html#Heart-beating) header of the CONNECT frame. 

### Minified version

In addition to the regular `stomp.js` file, the library is also available in a minified version `stomp.min.js`

### Annotated source

The source is now [documented](http://jmesnil.net/stomp-websocket/stomp.html) :)
