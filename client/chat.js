$(document).ready(function(){
  $('#sign_in_form').submit(NodeJsChat.signIn);
  $('#chat_form').submit(NodeJsChat.onformsubmit);
  $(window).unload(function () {
    if (NodeJsChat.ws) NodeJsChat.ws.close();
    // So ugly :(
    NodeJsChat.windowClosing = true;
  });
});

NodeJsChat = {
  nick: null,
  windowClosing: false,
  ws: null,

  connect: function() {
    NodeJsChat.ws = new WebSocket("ws://localhost:61613");
    NodeJsChat.ws.onmessage = NodeJsChat.onmessage;
    NodeJsChat.ws.onclose   = NodeJsChat.onclose
    NodeJsChat.ws.onopen    = NodeJsChat.onopen;
  },

  // This doesn't belong here buttttttttttt....
  debug: function(str) {
    $("#debug").append("<p>"+str+"</p>");
  },

  onclose: function() {
    NodeJsChat.debug('socket closed');
    if (!NodeJsChat.windowClosing) {
      alert('Whoops! Looks like you lost internet connection or the server went down');
    }
  },

  onformsubmit: function() {
    var message = $('#chat_form_input').val();
    if (message != '') {
      NodeJsChat.say(message);
      $('#chat_form_input').val('');
    }

    return false;
  },

  onmessage: function(evt) {
    var jsonData = JSON.parse(evt.data);

    var action  = jsonData[0];
    var data    = jsonData[1];

    if (NodeJsChat.handlers[action]) {
      NodeJsChat.handlers[action](data);
    }
    else {
      // This should be in a separate function.
      $('#messages').append('<tr><td cospan="2">Whoops, bad message from the server</td></tr>');
    }
  },

  onopen: function() {
    NodeJsChat.debug('Connected...');
    NodeJsChat.send([ 'assignNick',  NodeJsChat.nick ]);
  },

  say: function(message) {
    NodeJsChat.send([ 'say',  message ]);
    return false;
  },

  send: function(data) {
    var dataStr = JSON.stringify(data);
    NodeJsChat.ws.send(dataStr);
  },

  signIn: function() {
    NodeJsChat.connect();
    NodeJsChat.nick = $('#sign_in_form_input').val()

    $('#sign_in_form_input').blur();
    $('#sign_in').fadeOut({ duration: 'fast' });
    $('#chat_form_input').removeAttr('disabled');
    $('#sign_in').remove();

    return false;
  }
};

NodeJsChat.handlers = {
  lastMessage: function(data) {
    for (var idx = 0; idx < data.length; ++idx) {
      var message = data[idx];
      NodeJsChat.handlers[message[0]](message[1]);
    }
  },

  said: function(data) {
    var message = '<div class="message">';

    var prefix  = '';
    var tdClass = '';
    if (data.isSelf) {
      prefix  = 'You:';
      tdClass = 'me';
    }
    else {
      prefix  = data.nick + ':';
      tdClass = 'nick';
    }
    message     += '<div class="' + tdClass + '">';
    message     += prefix
    message     += '</div>';

    message     += '<div class="message">';
    message     += data.message;
    message     += '</div>';

    if (data.timestamp)
    {
      message     += '<div class="timestamp">@ ';
      message     += new Date(data.timestamp);
      message     += '</div>';
    }
    message     += '</div>';

    $('#messages').append(message);
  },

  status: function(data) {
    var nick = data.nick;
    var stat = data['status'];

    var message = '<div class="status">' + nick + ' just logged ' + stat + '</div>';
    $('#messages').append(message);
  }
};
