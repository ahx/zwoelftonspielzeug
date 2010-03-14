# encoding: UTF-8
require 'em-websocket'
require 'json'
module Zwoelftonspielzeug  
  class WebsocketServer 
    def initialize(zeug)
      zeug.spiel.add_observer(self)
      zeug.add_observer(self)
      @zeug = zeug
      @channel = EM::Channel.new
    end
  
    def update(origin, event, data)
      msg = {
        :type => event, 
        :data => data
        }
      broadcast msg
    end
  
    def broadcast(message)
      @channel.push message.to_json  
    end
  
    def run
      Thread.new {
        EventMachine::WebSocket.start(:host => '0.0.0.0', :port => 7779) { |ws|          
          ws.onopen   { 
            @channel.subscribe { |msg| ws.send msg }             
            }
          ws.onmessage { |msg| 
            return unless msg == 'init'
            ws.send({   
              :type => :init,           
              :data => {                
                :reihe => @zeug.spiel.reihe,
                :umkehrung => @zeug.spiel.umkehrung,
                :akkordkrebs => @zeug.spiel.akkordkrebs?,
                :transposition => @zeug.spiel.transposition                
              }
            }.to_json)
          }
          ws.onclose  { puts "WebSocket closed" }    
        }
      }
    end
  end
end