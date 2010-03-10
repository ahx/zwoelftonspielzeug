# encoding: UTF-8
require 'em-websocket'
require 'json'
module Zwoelftonspielzeug  
  class WebsocketServer 
    def initialize(zeug)
      zeug.spiel.add_observer(self)
      zeug.add_observer(self)
      @channel = EM::Channel.new
    end
  
    def update(param, value, origin, opts = {})
      msg = {
        :type => :update, 
        :param => param, 
        :value => value 
        }.merge!(opts)
      broadcast msg
    end
  
    def broadcast(message)
      @channel.push message.to_json  
    end
  
    def run
      Thread.new {
        EventMachine::WebSocket.start(:host => '0.0.0.0', :port => 7779) { |ws|          
          ws.onopen   { @channel.subscribe { |msg| ws.send msg } }
          # ws.onmessage { |msg| ws.send "Pong: #{msg} #{@spiel.reihe}" }
          ws.onclose  { puts "WebSocket closed" }    
        }
      }
    end
  end
end