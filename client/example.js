$(document).ready(function(){

  var client;
  
  $('#connect_form').submit(function() {
    url = $("#connect_url").val();
    login = $("#connect_login").val();
    passcode = $("#connect_passcode").val();
    destination = $("#destination").val();
    
    client = stomp(url);
    client.debug = function(str) {
      $("#debug").append(str + "\n");
    };
    client.onreceive = function(message) {
      debug("received " + message);
    };
    client.onconnect = function() {
      debug("connected to Stomp");
      $('#connect').fadeOut({ duration: 'fast' });
      $('#connect').remove();
      $('#send_form_input').removeAttr('disabled');
    };
    client.ondisconnect = function() {
      debug("disconnected from Stomp");
    };

    client.connect(login, passcode);
    
    // FIXME simutate opening the web socket
    client.onopen();
    // FIMXE simulate CONNECTED response
    client.onmessage(new Frame("CONNECTED"));

    client.subscribe(destination);

    client.send(destination, {foo: 1}, "hello, world!");
    
    // FIXME simutate receiving a message
    message = new Frame("MESSAGE", {destination: destination, foo: 1},
                          "hello, world!");
    client.onmessage(message);
    
    client.unsubscribe(destination)
    client.disconnect();

    return false;
  });
});