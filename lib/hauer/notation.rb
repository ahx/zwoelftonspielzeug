# encoding: UTF-8

module Hauer  
  # Notation von Noten und Pausen
  module Notation
    module_function
    
    def Note(pitch, note_value, options = {})
      opt = {
        :velocity => 80
      }.merge!(options)
      velocity = 
      MidiNote.new(pitch, note_value, opt[:velocity])
    end
  end
  
  class MidiNote < Struct.new(:pitch, :value, :velocity)
  end
end
