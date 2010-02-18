# encoding: UTF-8

# require 'rubygems'
require 'midiator'


$LOAD_PATH << File.dirname(__FILE__) + '/lib'
require 'hauer/zwoelftonspiel.rb'
require 'hauer/utils'
include Hauer::Utils

# Ein Zwölftonspiel konzipieren…
spiel = Hauer::Zwoelftonspiel.new

# Reihe aus J.M. Hauers Zwölftonspiel für Flöte und Cembalo vom 31. August 1948
spiel.reihe = %w(h des d b as f es ges a fes c g).map{ |n| note2midi(n)+50}
# Reihe aus J.M. Hauers Zwölftonspiel für Cembalo oder Klavier 11. Juni 1955
# spiel.reihe =  [57, 51, 48, 47, 55, 56, 49, 52, 46, 54, 53, 50]
# Zufällig gewählte Reihe
# spiel.reihe = (60..71).to_a.shuffle

puts "Reihe ok? #{spiel.reihe_ok?}"

# Zwölftonspiel abspielen…
midi = MIDIator::Interface.new
# midi.autodetect_driver
midi.use(:dls_synth) # OSX Synth
  
# Melodie und Klangreihe zusammen spielen!
#loop do
  # spiel.reihe.shuffle!
  melodie  = spiel.melodie(:flach => false, :gattung => 4)
  klangreihe = spiel.klangreihe
  melodie.each_with_index {|noten, i|
    akkord = klangreihe[i]
    noten.each_with_index {|note, ni|  
      l = 0.6 / noten.length
      puts "#{note}, #{l}"    
      n = ni.zero? ? akkord.map!{|n| n+12} << note : note
      midi.play n, l
    }    
  }

  # Schlussakkord spielen
  schlussakkord = klangreihe[0] << spiel.reihe[0]
  puts "Schlusston #{schlussakkord}"
  midi.play schlussakkord, 1
#end
