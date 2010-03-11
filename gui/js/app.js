var ws;
// The thing
var zwoelftonspielzeug = {
  init: function() {
    this.zyklus = Raphael("zyklus", 650, 385);      
    this.drawCycle();
  },
      
  drawCycle: function() {
    var r = this.zyklus;
    // r.clear();
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
      r.circle(r.width/2, r.height/2, radius).attr({
        "stroke": "#222",
        "stroke-width": 1,
        "stroke-opacity": 0,
        "fill": "white",
        "fill-opacity": 0,
      }).animate({fill: colors[i], "stroke-opacity": 0.6, "fill-opacity": 0.9 }, Math.random()*1500 + 500 , 'backOut');
    });
    this._drawRow();
  },

  // FIXME Refactor  
  _drawRow: function() {
    var r = this.zyklus;
    var pos = _.map(this._normalizeRow(this.data.reihe), function(note, i) {
      var deg = (i*(360/12) / 180 * Math.PI);
      var orb = 15*note + 22;
      var x = (Math.sin(deg)*orb)+r.width/2;
      var y = (Math.cos(deg)*orb)+r.height/2;
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
  },
  
  _normalizeRow: function(notes) {
    var min = _.min(notes);
    return _.map(notes, function(n) {
      return n - min;
    });  
  },
  
  update: function(data) {
    var value = data.value;
    // Unterschiedliche Formatierung, je nach key…
    if( data.key == 'akkordkrebs') value = data.value ? 'Ja' : 'Nein';
    if( data.key.match("stimme")) {
      if(!value && value !== 0) value = "x";
    }
    if( data.key == 'reihe') {    
      this.drawCycle();
      return;
    }
    // Tu es!
    $("#wert-"+data.key).html(value);
  }
}

$(document).ready(function(){
  ws = new WebSocket("ws://localhost:7779/");
  ws.onmessage = function(evt) { 
    var data = JSON.parse(evt.data)
    // consoles.log(daxta);
    switch(data.type) {
      case 'init':
        zwoelftonspielzeug.data = data.data;
        zwoelftonspielzeug.init();
      break;
      case 'update':
        zwoelftonspielzeug.update(data);
      break;
    }
  };
  ws.onclose = function() { 
    alert("Bitte Zwölftonspielzeug starten und neu laden."); 
  };
  ws.onopen = function(evt) {  
    ws.send("hello"); 
  };
});
