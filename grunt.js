module.exports = function( grunt ) {
  grunt.initConfig({
    
    pkg: "<json:package.json>",
    meta: {
      banner: "/*! Stomp Over WebSocket v<%= pkg.version %> http://www.jmesnil.net/stomp-websocket/doc/ | Apache License V2.0 */"
    },

    min: {
      dist: {
        src: ['<banner>', 'dist/stomp.js'],
        dest: 'dist/stomp.min.js'
      }
    }
  })
}
