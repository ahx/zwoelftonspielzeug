// Globals
var zyklus;
var Data;
function drawCycle() {
  console.log("drawCycle");
  var notes = Data.reihe;
  var width = 650;
  var height = 380;
  var r = zyklus;
  r.clear();
  // r.rect(0,0,width,height).attr({'fill': 'red', 'stroke-width': 0});
  var colors = [
  "#EDAA47",
  "#7C4E72",
  "#E6CF85",
  "#DF311E",
  "#88A293",
  "#D05930",
  "#3B58C7",
  "#E9AE4E",
  "#D46FB0",
  "#A6AA59",
  "#D2391E",
  "#4C654F"
  ];
  _.times(12, function(i){     
    var radius = 188-(i*15);
    r.circle(width/2, height/2, radius).attr({
      "stroke": "#222",
      "stroke-width": 1,
      "stroke-opacity": 0,
      "fill": "white",
      "fill-opacity": 0,
    }).animate({fill: colors[i], "stroke-opacity": 0.6, "fill-opacity": 0.9 }, Math.random()*1500 + 500 , 'backOut');
  });
  _drawRow(notes);
}
// FIXME Refactor
function _drawRow(notes) {
  var width = 650;
  var height = 380;
  var r = zyklus;  
  var pos = _.map(_normalizeRow(notes), function(note, i) {
    var deg = (i*(360/12)   / 180 * Math.PI);
    var orb = 15*note + 22;
    var x = (Math.sin(deg)*orb)+width/2;
    var y = (Math.cos(deg)*orb)+height/2;
    return [x, y];
  });
  var mapleP = "M"+pos[0][0]+" "+pos[0][1]
  for (var i = pos.length - 1; i >= 0; i--) {    
    mapleP += "L"+pos[i][0]+" "+pos[i][1];
  };
  var style = {fill: '#F9F6E3', "stroke-opacity": 0, "fill-opacity": 0};
  // Draw maple polygon fist
  r.path(mapleP).attr(style).animate({"stroke-opacity": 0.6, "fill-opacity":1}, 500, 'backOut');
  // then draw points / notes
  _.each(pos, function(p) {
   r.circle(p[0], p[1], 7).attr(style).animate({"stroke-opacity": 0.6, "fill-opacity":1}, 500, 'backOut'); 
  });
}
function _normalizeRow(notes) {
  var min = _.min(notes);
  return _.map(notes, function(n) {
    return n - min;
  });  
}
function update(data) {
  var key = data.key;
  var value = data.value;
  Data[key] = value;
  // Unterschiedliche Formatierung, je nach key…
  if( data.key == 'akkordkrebs') value = data.value ? 'Ja' : 'Nein';
  if( data.key.match("stimme")) {
    if(!value && value !== 0) value = "x";
  }
  if( data.key == 'reihe') {    
    drawCycle();
    return;
  }
  // Tu es!
  $("#wert-"+key).html(value);
}
function init() {
  drawCycle();
}

$(document).ready(function(){
  function debug(str){ $("#debug").append("<p>" +  str); }
  var ws = new WebSocket("ws://localhost:7779/");
  ws.onmessage = function(evt) { 
    var data = JSON.parse(evt.data)
    switch(data.type) {
      case 'init':
        Data = data.data;
        init();
      break;
      case 'update':
        update(data);
      break;
      default: debug("Dunno " + data.type);
    }
  };
  ws.onclose = function() { 
    alert("Bitte Zwölftonspielzeug starten und neu laden."); 
  };
  ws.onopen = function(evt) {  
    ws.send("hello"); 
  };
  // setTimeout(function() {init();}, 300);   
  zyklus = Raphael("zyklus", 650, 385);      
});
