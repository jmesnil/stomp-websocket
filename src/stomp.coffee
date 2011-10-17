class Stomp
  constructor: (@url, @options) ->

if window?
  window.Stomp = Stomp
else
  exports.Stomp = Stomp