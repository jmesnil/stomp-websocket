(function() {
  var Stomp;
  Stomp = (function() {
    function Stomp(url, options) {
      this.url = url;
      this.options = options;
    }
    return Stomp;
  })();
  if (typeof window !== "undefined" && window !== null) {
    window.Stomp = Stomp;
  } else {
    exports.Stomp = Stomp;
  }
}).call(this);
