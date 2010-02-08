# Stomp over Web Socket 

The project is hosted on [GitHub](http://github.com/jmesnil/stomp-websocket).

The library file is located in `src/stomp.js`.  
It does not require any dependency (except Web Socket support from the browser!)

A online [documentation][doc] describes the library API.

## Test

* Checkout the project
* Make sure you have a running Stomp broker which supports the Web Sockets protocol
 (see the [documentation][doc])
* Open in your web browser the project's [test page](test/index.html)
* Check all tests pass

## Use

The project contains an [chat example](example/chat/index.html) using stomp-websockets
to send and receive Stomp messages from a server.

## Contribute

    git clone git://github.com/jmesnil/stomp-websocket.git

[doc]: http://jmesnil.net/stomp-websocket/doc/