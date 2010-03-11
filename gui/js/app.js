$(document).ready(function(){
  function debug(str){ $("#debug").append("<p>" +  str); };
  ws = new WebSocket("ws://localhost:7779/");
  ws.onmessage = function(evt) { 
    var data = JSON.parse(evt.data);
    var key = data.key;
    var value = data.value;
    // Unterschiedliche Formatierung, je nach key…
    if( data.key == 'akkordkrebs') value = data.value ? 'Ja' : 'Nein';
    if( data.key =~ /stimme/) {
      if(!value && value !== 0) value = "x";
    }
    // Tu es!
    $("#wert-"+key).html(value);
  };
  ws.onclose = function() { 
    // alert("Bitte Zwölftonspielzeug starten und neu laden."); 
  };
  // ws.onopen = function() {};
});
