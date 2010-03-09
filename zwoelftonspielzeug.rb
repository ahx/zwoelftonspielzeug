# encoding: UTF-8
# Language: Denglisch
require 'rubygems' # TODO Remove. Use Bundler
require 'midiator'
require 'gamelan'
require 'osc-ruby'
$LOAD_PATH << File.dirname(__FILE__) + '/lib'
require 'hauer'

module Zwoelftonspielzeug
  include Hauer::Notation

  unless defined? BasicObject
    warn "Defining BasicObject!"
    # This is all we really need…
    class BasicObject; end
  end
  
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
        note, velocity, channel = p message.to_a
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
  
  # Empfängt parameter für das Zwölftonspiel und Sendet MIDI Signale 
  class Automat
    include Hauer::Notation
    attr :spiel
    attr :scheduler
    attr :stimmen
    attr :proxy
 
    def initialize
      @stimmen = Struct.new(:bass, :tenor, :alt, :sopran).new
      @spiel = Hauer::Zwoelftonspiel.new
      @proxy = Proxy.new(@spiel)
      @scheduler = Gamelan::Scheduler.new :tempo => 80      
      @eingang = OSCInput.new(self, 7778)
      @eingang.start
      # Wir schicken note_on und note_off an die gleiche Adresse und schicken bei note_off velocity 0
      # Das vereinfacht die Zusammenarbeit mit PureData
      @ausgang = OSCOutput.new('localhost', 7777, :note_off_path => '/note', :note_on_path => '/note')
      # Alter MIDI Treiber
      # @ausgang = MIDIator::Interface.new
      # @ausgang.use :core_midi      
      # @ausgang.use :dls_synth
    end

    def start
      zwoelfschlag(0)
      @scheduler.run
    end
    
    # Stop bei nächsten Zwölfschlag
    def stop
      @stop = true
    end
    
    # Alle zwölf Takte soll etwas passieren
    def zwoelfschlag(zeit)    
      return puts "ctrl+c to quit!" if @stop  
      stimmen_schedulen!(zeit)      
      neustart_zwoelfschlag(zeit)
    end
    
    def stimmen_schedulen!(start)
      beat_offset = start
      @stimmen.each_with_index { |stimme, index|
        beat_offset = start
        next unless stimme
        noten = stimme.is_a?(Proc) ? stimme.call : stimme
        noten.each {|note|      
          beat_offset += _schedule_note(beat_offset, note, index+1) # channel !
        }
      }
      # @scheduler.at(beat_offset+1) { @scheduler.stop } # schedule shutdown
    end
    
    # Zwölfschlag anschlagen
    def neustart_zwoelfschlag(start = 0)
      zeit = start + @spiel.takt.laenge * 12
      @scheduler.at(zeit) { zwoelfschlag(zeit) }
    end        
    
    def play_note(time_in_beats, note, channel)
      @scheduler.at(time_in_beats + note.offset) { @ausgang.note_on(note.pitch, channel, note.velocity) }
      # 0 bei note_off (s.o.)
      @scheduler.at(time_in_beats + note.offset + note.value) { @ausgang.note_off(note.pitch, channel, 0) }    
    end
    
    
    def _schedule_note(beat_offset, note, channel)
      # Bei listen von Noten gehen wir davon aus, dass alle Noten gleich lang sind! FIXME ?    
      case note 
      when Array
        note.each{|n| play_note(beat_offset, n, channel) }
        note.last.value + note.last.offset
      else
        play_note(beat_offset, note, channel)
        note.value + note.offset
      end
    end
  end
  
  # Gibt einen Proc zurück, statt die Methode direkt aufzurufen. (Ganz nützlich.)
  class Proxy < BasicObject
    def initialize(receiver)
      @receiver = receiver
    end
    def method_missing(name, *args)
      ::Kernel.raise ::NoMethodError.new(name) unless @receiver.respond_to? name
      ::Proc.new { @receiver.send name, *args }
    end
  end
end
