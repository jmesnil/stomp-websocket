Frame = function(command, headers, body) {
  this.command = command;
  this.headers = headers;
  this.body = body;
  this.toString = function() {
    frame = command + '\n';
    for (header in headers) {
      if(headers.hasOwnProperty(header)) {
        frame = frame + header + ': ' + headers[header] + '\n';
      }
    }
    frame = frame + '\n';
    if (body) {
      frame = frame + body;
    }
    return frame;
  };
}

unmarshall = function(evt) {
  // this is where the Stomp frame will be unmarshalled
  // and a Frame created.
  // For now, we hack by having evt BE a Frame :(
  return evt;
}

marshall = function(command, headers, body) {
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
  out = out + '\0';
  return out;
}