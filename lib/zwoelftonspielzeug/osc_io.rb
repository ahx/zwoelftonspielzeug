# encoding: UTF-8
require 'osc-ruby'
require 'osc-ruby/em_server'

module Zwoelftonspielzeug  
  # Schickt Noten an PureData
  class OSCOutput
    def initialize(uri, port, options = {})
      @note_on_path = options.fetch(:note_on_path, '/note_on')
      @note_off_path = options.fetch(:note_off_path, '/note_off')
      @client = OSC::Client.new(uri, port)
    end
      
    def note_on(pitch, channel, velocity)
      # NOTE Wir schicken hier in der Reihenfolge channel, pitch, velocity !
      @client.send( OSC::Message.new( @note_on_path, channel, pitch, velocity ))
    end
  
    def note_off(pitch, channel, velocity)
      @client.send( OSC::Message.new( @note_off_path, channel, pitch, velocity ))
    end
  
    def close; end # FIXME Remove. This is just to look like a Midiator driver
  end

  # Empfängt Eingaben vom MIDI Controller.
  # Bei MVC wäre das hier ein Controller    
  class OSCInput
    def initialize(ziel, port)
      @ziel = ziel
      @eingang = OSC::EMServer.new( port )
      @spiel = @ziel.spiel
      @proxy = @ziel.proxy
      configure
    end

    def configure
      # NOTE Die control signale sind in PD schon auf den Bereich 0..11 gemapped.
      @eingang.add_method '/control' do | message |
        value, controller, channel = message.to_a
        case controller
        when 1,2,3,4
          puts "Stimme #{controller}: #{value}"
          @ziel.stimmen[controller-1] = stimmvariation(value)
        when 5
          puts "Umkehrung: #{value}"
          @spiel.umkehrung = value
        when 6 
          puts "Transposition: #{value}"
          @spiel.transposition = value
        else
          p message.to_a
        end
      end
      @eingang.add_method '/note' do | message |
        note, velocity, channel = message.to_a
      case note
      when 39
        # TODO toggle einbauen!        
        @spiel.akkordkrebs = !velocity.zero?
        puts "Akkordkrebs: #{@spiel.akkordkrebs? ? "Ja" : "Nein"}"
      end
      end
    end      
      
    def start
      Thread.new do
        @eingang.run
      end
    end
  
    # Gibt je nach Wert eine Melodievariante / Klangreihe zurück
    def stimmvariation(num)
      {  
        0 => @proxy.klangreihe,      
        1 => @proxy.melodie(:gattung => 1),
        2 => @proxy.melodie(:gattung => 2),
        3 => @proxy.melodie(:gattung => 3),
        4 => @proxy.melodie(:gattung => 4),
        5 => @proxy.melodie(:gattung => 5),        
        6 => proc { Hauer::Arpeggiator.arpeggio!(@spiel.klangreihe, :reverse => @spiel.akkordkrebs?) },
        7 => proc { Hauer::Arpeggiator.arpeggio!(@spiel.klangreihe, :reverse => @spiel.akkordkrebs?, :arp => 0.1) }
      }[num]
    end
  end  
end
