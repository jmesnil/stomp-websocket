Frame = function(command, headers, body) {
  this.command = command;
  this.headers = headers;
  this.body = body;
  this.toString = function() {
    out = command + '\n';
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
  };
}

unmarshall = function(evt) {
  // this is where the Stomp frame will be unmarshalled
  // and a Frame created.
  // For now, we hack by having evt BE a Frame :(
  return evt;
}

marshall = function(command, headers, body) {
  frame f = new Frame(command, headers, body);
  return f.toString();
}