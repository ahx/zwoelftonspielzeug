# encoding: UTF-8

module Hauer
  
module Utils
  NOTEN = [%w(c), %w(cis des),  %w(d), %w(dis es), %w(e fes), %w(f eis), %w(fis ges), %w(g), %w(gis as), %w(a), %w(b ais), %w(h ces)]
  
  def midi2note(note)
    # Wir schreiben hier "fes" statt "e", weil Sengstschmid das auch so gemacht hat
    NOTEN[note % 12].first
  end
  module_function :midi2note
  
  def note2midi(name)
    NOTEN.each_with_index { |namen, midi| 
      return midi if namen.include?(name)
    }
    nil
  end
  module_function :note2midi
end

end

# Midi
# 0 = :c1
# 1 = :cs1
# 60 = :c4

# Stolen from Jeremy Voorhis' diatonic http://github.com/jvoorhis/diatonic
# Convert midi note numbers to hertz.
# def mtof(pitch)
#   440.0 * (2.0 ** ((pitch.to_f-69)/12))
# end
# 
# # Convert hertz to midi note numbers.
# def ftom(pitch)
#   (69 + 12 * (Math.log2(pitch / 440.0))).round
# end

