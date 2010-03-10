# encoding: UTF-8
require 'em-websocket'

class WebsocketServer    
  def initialize(zeug)
    @spiel = zeug.spiel
    @spiel.add_observer(self)
    @channel = EM::Channel.new
  end
  
  def update(param, value, origin)
    puts param, value, origin
  end
  
  def run
    Thread.new {
      EventMachine::WebSocket.start(:host => "0.0.0.0", :port => 7779) { |ws|          
        ws.onopen    { ws.send "Hello Client!"}
        ws.onmessage { |msg| ws.send "Pong: #{msg} #{@spiel.reihe}" }
        ws.onclose   { puts "WebSocket closed" }                    
      }
    }
  end
end
