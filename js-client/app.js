window.onload = function() {

  // Get references to elements on the page.
  var form = document.getElementById('message-form');
  var messageField = document.getElementById('message');
  var messagesList = document.getElementById('messages');
  var socketStatus = document.getElementById('status');
  var runBtn = document.getElementById('run');


  // Create a new WebSocket.
  var socket = new WebSocket(
      'ws://192.168.1.35:5555', ['bus.sp.nanomsg.org']);
      // see the rfc on sp websocket mapping:
      // raw.githubusercontent.com/nanomsg/nanomsg/master/rfc/sp-websocket-mapping-01.txt 

  // Handle any errors that occur.
  socket.onerror = function(error) {
    console.log('WebSocket Error: ' + error);
  };


  // Show a connected message when the WebSocket is opened.
  socket.onopen = function(event) {
    //socketStatus.innerHTML = 'Connected to: ' + event.currentTarget.URL;
    socketStatus.innerHTML = 'connected';
    socketStatus.className = 'open';
  };


  // Handle messages sent by the server.
  socket.onmessage = function(event) {
    var message = event.data;
    messagesList.innerHTML = message + messagesList.innerHTML;
  };


  // Show a disconnected message when the WebSocket is closed.
  socket.onclose = function(event) {
    socketStatus.innerHTML = 'disconnected';
    socketStatus.className = 'closed';
  };


  // Send a message when the form is submitted.
  form.onsubmit = function(e) {
    e.preventDefault();

    // Retrieve the message from the textarea.
    var message = messageField.value;

    // Send the message through the WebSocket.
    socket.send(message);

    // Add the message to the messages list.
    messagesList.innerHTML = '> ' + message + messagesList.innerHTML;

    // Clear out the message field.
    messageField.value = '';

    return false;
  };


  runBtn.onclick = function(e) {
	e.preventDefault();
	var message = "norns.run()\n";
	socket.send(message);
	return false;
  };

};
