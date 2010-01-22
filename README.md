# Stomp over Web Socket 

The project is hosted on [GitHub](http://github.com/jmesnil/stomp-websocket).

## Build

To build the library, use Apache Ant from the root directory:

    $ cd stomp-websocket
    $ ant
    Buildfile: build.xml

    build:
        [mkdir] Created dir: /Users/jmesnil/Git/stomp-websocket/dist
         [echo] created dist/stomp.js

    BUILD SUCCESSFUL
    Total time: 0 seconds
    
The library file will be located in `dist/stomp.js`.  
It does not require any dependency (except Web Socket support from the browser!)

## Test

* Build the library
* Open in your web browser the [test page](test/index.html)
* Check all tests pass

## Use

The project contains an [example](example/index.html) using stomp-websockets
to send and receive Stomp messages from a server.

## Contribute

    git clone git://github.com/jmesnil/stomp-websocket.git