# Stomp over Web Socket 

This is a fork based on the work by [jmsenil](http://github.com/jmesnil/stomp-websocket). The goals are:

 * Better mocking of a Stomp WebSocket server
   * Eliminating the need for running a broker to test
 * Node.js based testing
   * No need for a browser
 * Stomp/1.1 compatibility
 * Rewrite in CoffeeScript (most contentious, I'm sure)
   * Cleaner/simpler, but still just JavaScript
 * Pluggable WebSocket objects (MozWebSocket, JsSock)

The project now depends on CoffeeScript, Node.js, and Jasmine for development, but in return testing does not depend on the browser. This project infrastructure will lead to better test coverage and better mocking. For this reason, the library will be more suited for building on top of it.

Online [documentation][doc] describes the library API.

## Requirements

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

## Authors

 * [jmsenil](http://github.com/jmesnil)
 * Jeff Lindsay

[doc]: http://jmesnil.net/stomp-websocket/doc/