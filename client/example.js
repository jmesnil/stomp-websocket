$(document).ready(function(){

  $('#connect_form').submit(function() {
    url = $("#connect_url").val();
    login = $("#connect_login").val();
    passcode = $("#connect_passcode").val();
    
    var client = stomp(url);
    client.onreceive = function(message) {
      debug(">>> got message " + message);
    }
    client.onconnect = function() {
      debug(">>> [CONNECTED] to Stomp ");
    };
    client.ondisconnect = function() {
      debug(">>> [DISCONNECTED] to Stomp ");
    };

    client.connect(login, passcode);
    
    // FIXME simutate openging the web socket
    client.onopen();
    // FIXME simutate receiving a message
    client.onmessage("wtf");
    
    client.disconnect();

    return false;
  });
});