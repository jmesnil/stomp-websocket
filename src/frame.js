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

trim = function(str) {
  return str.replace(/^\s+/g,'').replace(/\s+$/g,'');
}

Stomp.unmarshall = function(data) {
  var command, headers, body;
  var lines = data.split('\n');
  command = lines[0];
  headers = {};
  var pos;
  for (pos = 1; pos < lines.length ; pos++) {
    if (lines[pos] === '') {
      break;
    }
    var pair = lines[pos].split(':');
    headers[trim(pair[0])] = trim(pair[1]);
  }
  pos++;
  if(lines[pos] === '') {
    // no body
  } else {
    body = "";
    for (i = pos; i < lines.length; i++) {
      if (i >= pos) {
        pos += '\n'
      }
      body += lines[i];
    }
  }
  return Stomp.frame(command, headers, body);
};

Stomp.marshall = function(command, headers, body) {
  return Stomp.frame(command, headers, body).toString() + '\0';
};