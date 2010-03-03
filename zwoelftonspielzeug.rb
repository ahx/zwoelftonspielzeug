# encoding: UTF-8
# Language: Denglisch
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
 
    def initialize
      @spiel = Hauer::Zwoelftonspiel.new
      @scheduler = Gamelan::Scheduler.new :tempo => 90
      @midi = MIDIator::Interface.new
      # @midi.autodetect_driver
      @midi.use(:dls_synth)
    end
 
    def start
      neustart_zwoelfschlag
      @scheduler.run
    end
    
    def stop
      @scheduler.stop
      @midi.close
    end
    
    # Alle zwölf Takte soll etwas passieren
    def zwoelfschlag(zeit)
      stimmen_komponieren!
      stimmen_schedulen!(zeit)
      neustart_zwoelfschlag(zeit)
    end
        
    # Das ganze komponieren!
    def stimmen_komponieren!
      @stimmen = []
      @stimmen << @spiel.klangreihe
      @stimmen << @spiel.melodie
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
      @scheduler.at(time_in_beats + note.offset) { @midi.note_on(note.pitch, channel, note.velocity) }
      @scheduler.at(time_in_beats + note.offset + note.value) { @midi.note_off(note.pitch, channel, note.velocity) }    
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


# automat = Zwoelftonspielzeug::Automat.new
# automat.spiel.verwende_akkordkrebs = true
# automat.spiel.umkehrung = 0
# Reihe aus J.M. Hauers Zwölftonspiel für Cembalo oder Klavier 11. Juni 1955
# automat.spiel.reihe =  [57, 51, 48, 47, 55, 56, 49, 52, 46, 54, 53, 50]
# automat.start
# Live coding!
# loop do
#   eval gets
# end
