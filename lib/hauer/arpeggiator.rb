# encoding: UTF-8

module Hauer  
  module Arpeggiator
    module_function
    
    def arpeggio!(noten, opts = {})
      o = {
       :arp => nil,
       :reverse => false
      }.merge!(opts)
      dauer = noten.max {|me, other| me.value <=> other.value }
      teil = o[:arp] || dauer.value / noten.length
      noten = noten.reverse if o[:reverse]
      noten.each_with_index { |note, i|
        note.value -= teil * i
        note.offset += teil * i
      }
    end    
  end
end
