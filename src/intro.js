// client can implement the eventhandlers:
// * onconnect    => to be notified when it is connected to the STOMP server
// * ondisconnect => to be notified when it is disconnected from the STOMP server
// * onreceive    => to receive STOMP messages
// * onreceipt    => to receive STOMP receipts
// * onerror      => to receive STOMP errors
//
// client can also define a debug(str) handler to display debug infos

(function(window) {
  
  var Stomp = {};
