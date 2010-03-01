# encoding: UTF-8

# TODO siehe thrdcom.rb!

require 'midiator'

$LOAD_PATH << File.dirname(__FILE__) + '/lib'
require 'hauer/zwoelftonspiel.rb'
require 'hauer/utils'
require 'hauer/notation'
include Hauer::Utils
# Ein Zwölftonspiel konzipieren…
spiel = Hauer::Zwoelftonspiel.new

# Reihe aus J.M. Hauers Zwölftonspiel für Flöte und Cembalo vom 31. August 1948
# spiel.reihe = %w(h des d b as f es ges a fes c g).map!{ |n| note2midi(n)+48}

# Reihe aus J.M. Hauers Zwölftonspiel für Cembalo oder Klavier 11. Juni 1955
spiel.reihe =  [57, 51, 48, 47, 55, 56, 49, 52, 46, 54, 53, 50]

# Reihe aus "Passacaglia für Klavier" von einer Bamberger Gymnasialklasse 1974
# http://www.musiker.at/sengstschmidjohann/mp3/sonstiges/passacaglia.mp3
# http://www.klangreihenmusik.at/skriptum-passacaglia-01kl.php3
# spiel.reihe = %w(e g cis d b c f a fis dis h gis).map{|n| note2midi(n) + 48}

# Zufällig gewählte Reihe
# spiel.reihe = (60..71).to_a.shuffle

puts "Reihe ok? #{spiel.reihe_ok?}"

# Zwölftonspiel abspielen…
midi = MIDIator::Interface.new
# midi.autodetect_driver
midi.use(:dls_synth) # OSX Synth

# Spiel-Eigenschaften 
# spiel.reihe.shuffle!
# spiel.verwende_akkordkrebs = true
# spiel.umkehrung = 0
# melodie = spiel.melodie(:gattung => 5)

# Melodie spielen!
# melodie.each {|note|
#   midi.play note.pitch, 0.5 * note.value
# }
# # Schlusskkord spielen
# include Hauer::Notation
# note = Note(spiel.klangreihe.first, 1)
# midi.play note.pitch, note.value

# Melodie über scheduler spielen!
@stimmen = []
@stimmen << spiel.melodie(:gattung => 1).each{|n| n.pitch -= 12}
@stimmen << spiel.melodie(:gattung => 3)
# @stimmen << spiel.melodie(:gattung => 3)
@midi = midi
require 'gamelan'
@scheduler = Gamelan::Scheduler.new({:tempo => 90})

def play_note(time_in_beats, note, channel=10)
  pitch = note.pitch
  duration, velocity = note.value, note.velocity
  @scheduler.at(time_in_beats) { @midi.note_on(pitch, channel, velocity) }
  @scheduler.at(time_in_beats + duration) { @midi.note_off(pitch, channel, velocity) }
end

def schedule_events  
  beat_offset = 0
  @stimmen.each { |stimme|        
    beat_offset = 0
    stimme.each {|note|
      play_note beat_offset, note
      beat_offset += note.value
    }
  }
  @scheduler.at(beat_offset+1) { @scheduler.stop } # schedule shutdown
end
schedule_events

@scheduler.run
@scheduler.join