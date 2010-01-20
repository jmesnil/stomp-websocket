$(document).ready(function(){
  $('#connect_form').submit(function() {
    url = $("#connect_url").val();
    login = $("#connect_login").val();
    passcode = $("#connect_passcode").val();
    
    client = new Stomp(url);
    client.receive = function(message)
    {
      debug(">>> got message " + message);
    }
    client.connect(login, passcode);
    //client.onmessage("wtf");
    return false;
  });
  
});