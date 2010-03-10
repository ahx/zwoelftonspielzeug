# encoding: UTF-8
# Language: Denglisch
#require 'midiator'
require 'gamelan'
$LOAD_PATH.unshift File.dirname(__FILE__)
require 'hauer'
require 'zwoelftonspielzeug/osc_io'
require 'zwoelftonspielzeug/websocket_io'

require 'observer'
module Zwoelftonspielzeug    
  # Verbindet Zwölftonspiel mit Eingabe und Ausgabe und allem…
  class Automat
    include Observable
    include Hauer::Notation
    attr :spiel
    attr :scheduler
    # NOTE Wenn stimme direkt per stimme[x]= verändert wird gibts keinen Event!
    attr :stimmen
    attr :proxy
 
    def initialize
      @stimmen = Struct.new(:bass, :tenor, :alt, :sopran).new
      @spiel = Hauer::Zwoelftonspiel.new
      @proxy = Proxy.new(@spiel)      
      @eingang = OSCInput.new(self, 7778)
      @eingang.start
      # Wir schicken note_on und note_off an die gleiche Adresse und schicken bei note_off velocity 0
      # Das vereinfacht die Zusammenarbeit mit PureData
      @ausgang = OSCOutput.new('localhost', 7777, :note_off_path => '/note', :note_on_path => '/note')
      # Alter MIDI Treiber
      # @ausgang = MIDIator::Interface.new
      # @ausgang.use :core_midi      
      # @ausgang.use :dls_synth
      @websocket = WebsocketServer.new(self)
      @websocket.run
    end

    def start(tempo = 80)
      @scheduler = Gamelan::Scheduler.new :tempo => tempo
      zwoelfschlag(0)
      @scheduler.run
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
    
    def stimmvariation!(stimmen_id, varianten_id)
      @stimmen[stimmen_id] = stimmvariation(varianten_id)
      changed
      notify_observers(:stimme, {stimmen_id => varianten_id}, self)
    end
    
    # Stop bei nächsten Zwölfschlag
    def stop
      @stop = true
    end
    
    def quit!
      # @scheduler.stop
      # @websocket.stop
      Kernel.exit
    end
    
    # Alle zwölf Takte soll etwas passieren
    def zwoelfschlag(zeit)    
      return quit! if @stop
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
  
  # Hilfsklassen
  unless defined? BasicObject
    warn "Defining BasicObject!"
    # This is all we really need…
    class BasicObject; end
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
