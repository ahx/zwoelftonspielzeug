// Get chrome
if(typeof(WebSocket) == "undefined") {
  if(confirm("Ihr Browser unterstützt keine Websockets. \nBesorgen Sie sich jetzt Google Chrome."))
    window.location.replace("http://www.google.com/chrome/");
}

var ws;
var zwoelftonspielzeug = {
  beat_index: 0,
  data: {},
  
  init: function(data) {    
    this.zyklus = Raphael("zyklus", 650, 390);
    // this.noten = Raphael("noten", 650, 150); 
    this.update(data);
    // this.attachListeners();
  },
      
  drawCycle: function() {
    var r = this.zyklus;
    r.clear();
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
  
  trigger: function(event, data) {    
    if(this[event]) this[event](data);
  },
  
  update: function(data) {    
    for (var attr in data)  {      
      this.data[attr] = data[attr];   // store data
      switch(attr) {
        case 'akkordkrebs':
          $('input#wert-akkordkrebs').attr('checked', data[attr]);
          break;
        case 'reihe':
          this.drawCycle();
          break;
        case 'umkehrung':
        case 'transposition':
          $('select[name=wert-'+attr+'] option[value='+data[attr]+']').attr('selected', true);      
          break;
        default:
          if( attr.match("stimme"))
            $('input[name=wert-'+attr+'][value='+(data[attr] || 'off')+']').click();
      }
    }
  },
  
  attachListeners: function() {
    $('input#wert-akkordkrebs').change(function(evt) {   
      ws.send(JSON.stringify({akkordkrebs: $(this).is(':checked')}));
    });
    $('select#wert-umkehrung').change(function(evt) {
      ws.send(JSON.stringify({umkehrung: $(this).val()}));
    });
    $('select#wert-transposition').change(function(evt) {
      ws.send(JSON.stringify({transposition: $(this).val()}));
    });
    _.each(['bass', 'tenor', 'alt', 'sopran'],function(s) {
      $('#stimmen input[name=wert-stimme-'+s+']').change(function(evt) {
        msg = {stimme: {}};
        msg.stimme[s] = $(this).val();
        ws.send(JSON.stringify(msg));
      });
    })
  },
  
  metrum: function(data) {
    // console.log(data.beat_index);
    // this.beat_index = data.beat_index;
    // if(data.beat_index == 0)
      // this.noten.clear();
    // $("h1").toggle(); 
    // TODO Aktuellen Schlag anzeigen
  },
  
  kontinuum: function(note) {
    // this.noten.circle((this.noten.width/12*this.beat_index), this.noten.height/12*(note.pitch % 12), 10).attr({fill: Raphael.getColor() })
  }
}

$(document).ready(function(){
  zwoelftonspielzeug.attachListeners();
  ws = new WebSocket("ws://localhost:7779/");
  ws.onmessage = function(evt) { 
    var event = JSON.parse(evt.data)
    zwoelftonspielzeug.trigger(event.type, event.data);
  };
  ws.onclose = function() { 
    if(confirm("Bitte Zwölftonspielzeug (start) starten.")){      
      window.location.reload();
    } else {
      window.close();  
    }
  };
  ws.onopen = function(evt) {  
    ws.send("init"); 
  };
});
