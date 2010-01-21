$(document).ready(function(){

  $('#connect_form').submit(function() {
    url = $("#connect_url").val();
    login = $("#connect_login").val();
    passcode = $("#connect_passcode").val();
    
    var client = stomp(url);
    client.onreceive = function(message) {
      debug("<<< " + message);
    }
    client.onconnect = function() {
      debug("<<< connected to Stomp");
    };
    client.ondisconnect = function() {
      debug("<<< disconnected from Stomp");
    };

    client.connect(login, passcode);
    
    // FIXME simutate openging the web socket
    client.onopen();

    client.send("/queue/test", {foo: 1}, "hello, world!");
    
    client.subscribe("/queue/test");
    
    // FIXME simutate receiving a message
    message = new Message({destination: "/queue/test", foo: 1},
                          "hello, world!");
    client.onmessage(message);

    client.unsubscribe("/queue/test");
    
    client.disconnect();

    return false;
  });
});