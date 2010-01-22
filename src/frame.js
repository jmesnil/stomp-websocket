// TODO frame function should not be exposed once we can really talk to a Stomp server
Stomp.frame = function(command, headers, body) {
  return {
    command: command,
    headers: headers,
    body: body,
    toString: function() {
      var out = command + '\n';
      if (headers) {
        for (header in headers) {
          if(headers.hasOwnProperty(header)) {
            out = out + header + ': ' + headers[header] + '\n';
          }
        }
      }
      out = out + '\n';
      if (body) {
        out = out + body;
      }
      return out;
    }
  }
};

Stomp.unmarshall = function(evt) {
  // this is where the Stomp frame will be unmarshalled
  // and a Frame created.
  // For now, we hack by having evt BE a Frame :(
  return evt;
};

Stomp.marshall = function(command, headers, body) {
  return Stomp.frame(command, headers, body).toString() + '\0';
};