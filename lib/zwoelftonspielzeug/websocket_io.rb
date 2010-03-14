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
            if(msg == 'init')
              ws.send({   
                :type => :init,           
                :data => {                
                  :reihe => @zeug.spiel.reihe,
                  :umkehrung => @zeug.spiel.umkehrung,
                  :akkordkrebs => @zeug.spiel.akkordkrebs?,
                  :transposition => @zeug.spiel.transposition                
                }
              }.to_json)
            elsif(msg == 'alea')            
              @zeug.spiel.reihe = @zeug.spiel.reihe.shuffle
            else
              handle_message(JSON.parse(msg))
            end
          }
          ws.onclose  { puts "WebSocket closed" }    
        }
      }
    end
    
    def handle_message(msg)
      # FIXME DRY
      return unless msg.is_a? Hash
      msg.each { |key, value|
        case key.to_sym
        when :umkehrung
          @zeug.spiel.umkehrung = value.to_i
          break;
        when :transposition
          @zeug.spiel.transposition = value.to_i
          break;
        when :akkordkrebs
          @zeug.spiel.akkordkrebs = !!value
          break;
        when :stimme
          return unless value.is_a? Hash
          value.each{|stimme, variante|
            @zeug.stimmvariation!(stimme.to_sym, variante.to_i)
          }          
          break;
        end
      }
    end
  end
end