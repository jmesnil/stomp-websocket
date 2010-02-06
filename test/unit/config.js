$(document).ready(function(){
  
  TEST = {
    destination : "/queue/test",
    login : "guest",
    password : "guest",
    url : "ws://localhost:61614/stomp",
  
    timeout: 2000
  };

  // fill server requirements:
  $("#test_url").text(TEST.url);
  $("#test_destination").text(TEST.destination);
  $("#test_login").text(TEST.login);
  $("#test_password").text(TEST.password);
});
