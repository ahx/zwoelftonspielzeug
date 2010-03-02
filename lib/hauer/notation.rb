# encoding: UTF-8

module Hauer  
  # Notation von Noten und Pausen
  module Notation
    module_function
    
    def Note(pitch, note_value, options = {})
      opt = {
        :velocity => 80,
        :offset => 0.0
      }.merge!(options)
      velocity = 
      MidiNote.new(pitch, note_value.to_f, opt[:velocity], opt[:offset])
    end
  end
  
  class MidiNote < Struct.new(:pitch, :value, :velocity, :offset)

    def <=>(other)
      self.pitch <=> other.pitch
    end

    def +(d)
      self.delta(d)
    end
    
    def -(d)
      self.delta(-d)
    end
    
    def delta(d)
      self.pitch += d
      self
    end
  end
end
