# Stomp over Web Socket 

The library file is located in `dist/stomp.js`.
It does not require any dependency (except WebSocket support from the browser!)

Online [documentation][doc] describes the library API.

## Development Requirements
For development (testing, building) the project requires Node.js, CoffeeScript, and Jasmine. This allows us to run tests without the browser continuously during development (see `cake watch`). 

 * Node.js and NPM
 * NPM packages
   * coffee-script
   * jasmine-node
   * growl (optional)

## Building and Testing

To build JavaScript:

    cake build

To run tests:

    cake test

To continuously run tests on file changes:

    cake watch

## Browser Tests

* Make sure you have a running Stomp broker which supports the Web Sockets protocol
 (see the [documentation][doc])
* Open in your web browser the project's [test page](browsertests/index.html)
* Check all tests pass

## Use

The project contains an [chat example](example/chat/index.html) using stomp-websockets
to send and receive Stomp messages from a server.

## Todo

 * Stomp/1.1 compatibility
 * Pluggable WebSocket objects (MozWebSocket, JsSock)

## Authors

 * [jmsenil](http://github.com/jmesnil)
 * [Jeff Lindsay](http://github.com/progrium)

[doc]: http://jmesnil.net/stomp-websocket/doc/