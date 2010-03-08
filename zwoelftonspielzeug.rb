# encoding: UTF-8
# Language: Denglisch
require 'rubygems' if RUBY_VERSION < '1.9'
require 'midiator'
require 'gamelan'
$LOAD_PATH << File.dirname(__FILE__) + '/lib'
require 'hauer'

module Zwoelftonspielzeug
  include Hauer::Notation
  
  # Empfängt parameter für das Zwölftonspiel und Sendet MIDI Signale 
  class Automat
    include Hauer::Notation
    attr :spiel
    attr :scheduler
    attr :stimmen
 
    def initialize
      @spiel = Hauer::Zwoelftonspiel.new
      @scheduler = Gamelan::Scheduler.new :tempo => 90
      @interface = MIDIator::Interface.new
      @interface.autodetect_driver
      # @interface.use(:core_midi)
      # @interface.use(:dls_synth)
      # TODO Fix midiator tco list midi devices!   
      # puts "There are#{MIDIator::Driver::CoreMIDI::C.mIDIGetNumberOfDestinations} midi destinations"
      # @interface.driver.destination = MIDIator::Driver::CoreMIDI::C.MIDIGetDestination(1)
      @stimmen = []
    end

 
    def start
      zwoelfschlag(0)
      @scheduler.run
    end
    
    def stop
      @scheduler.stop
      @interface.close
    end
    
    # Alle zwölf Takte soll etwas passieren
    def zwoelfschlag(zeit)
      stimmen! # TODO remove
      stimmen_schedulen!(zeit)
      neustart_zwoelfschlag(zeit)
    end
            
    # Stimmen default initialisieren
    def stimmen!            
      @stimmen = []
      # @stimmen << @spiel.melodie(:gattung => 1)
      # @stimmen << @spiel.klangreihe.map{|a| a.map{|n| n - 12} }
      @stimmen << @spiel.melodie # 5. Gattung
      # @stimmen << @spiel.melodie(:gattung => 2).map{|n| n + 24}
      spiel.reihe
    end
    
    def stimmen_schedulen!(start)      
      beat_offset = start
      @stimmen.each { |stimme|
        beat_offset = start
        stimme.each {|note|
          beat_offset += _schedule_note(beat_offset, note)
        }
      }
      # @scheduler.at(beat_offset+1) { @scheduler.stop } # schedule shutdown
    end
    
    # Zwölfschlag anschlagen
    def neustart_zwoelfschlag(start = 0)
      zeit = start + @spiel.takt.laenge * 12
      @scheduler.at(zeit) { zwoelfschlag(zeit) }
    end        
    
    def play_note(time_in_beats, note, channel=10)
      @scheduler.at(time_in_beats + note.offset) { @interface.note_on(note.pitch, channel, note.velocity) }
      @scheduler.at(time_in_beats + note.offset + note.value) { @interface.note_off(note.pitch, channel, note.velocity) }    
    end
    
    
    def _schedule_note(beat_offset, note)
      # Bei listen von Noten gehen wir davon aus, dass alle Noten gleich lang sind! FIXME ?    
      case note 
      when Array
        note.each{|n| play_note(beat_offset, n) }
        note.last.value + note.last.offset
      else
        play_note(beat_offset, note)
        note.value + note.offset
      end
    end
  end
end


a = Zwoelftonspielzeug::Automat.new
# a.spiel.akkordkrebs = true
# a.spiel.umkehrung = 0
# Reihe aus J.M. Hauers Zwölftonspiel für Cembalo oder Klavier 11. Juni 1955
a.spiel.reihe =  [57, 51, 48, 47, 55, 56, 49, 52, 46, 54, 53, 50]
a.start
a.scheduler.join
# Live coding!
# s = a.spiel
# loop do
#   eval gets
# end
