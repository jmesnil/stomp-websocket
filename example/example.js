$(document).ready(function(){

  var client, destination;

  $('#connect_form').submit(function() {
    var url = $("#connect_url").val();
    var login = $("#connect_login").val();
    var passcode = $("#connect_passcode").val();
    destination = $("#destination").val();

    client = Stomp.client(url);

    // this allows to display debug logs directly on the web page
    client.debug = function(str) {
      $("#debug").append(str + "\n");
    };
    // the client is notified when it is connected to the server.
    client.onconnect = function(frame) {
      debug("connected to Stomp");
      $('#connect').fadeOut({ duration: 'fast' });
      $('#connect').remove();
      $('#send_form_input').removeAttr('disabled');
      
      client.subscribe(destination, {}, function(message) {
        $("#messages").append("<p>" + message.body + "</p>\n");
      });
    };
    // the client is notified when it is disconnected from the server.
    client.ondisconnect = function() {
      debug("disconnected from Stomp");
    };

    client.connect(login, passcode);

    return false;
  });
  
  $('#send_form').submit(function() {
    var text = $('#send_form_input').val();
    client.send(destination, {foo: 1}, text);
    $('#send_form_input').val("");
    return false;
  });
  
});