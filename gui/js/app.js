$(document).ready(function(){
  function debug(str){ $("#debug").append("<p>" +  str); };
  ws = new WebSocket("ws://localhost:7779/");
  ws.onmessage = function(evt) { 
    var data = JSON.parse(evt.data);
    var key = data.key;
    var value = data.value;
    switch(data.key){
      case 'akkordkrebs':
        value = data.value ? 'Ja' : 'Nein';
      break;
    };
    $("#wert-"+key).html(value);
  };
  ws.onclose = function() { alert("Bitte Zwölftonspielzeug starten und neu laden."); };
  // ws.onopen = function() {};
});
