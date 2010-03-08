# encoding: UTF-8

module Hauer  
  module Arpeggiator
    module_function
    
    def arpeggio!(noten, opts = {})
      if noten.first.is_a? Array
        return noten.map! {|n| arpeggio!(n, opts)}
      end
      o = {
       :arp => nil,
       :reverse => false
      }.merge!(opts)
      dauer = noten.max {|me, other| me.value <=> other.value }
      teil = o[:arp] || dauer.value / noten.length
      noten = noten.reverse if o[:reverse]
      noten.each_with_index { |note, i|
        note.value -= teil * i
        # TODO remove. Verhindert hackeln beim Abspielen(?). Behebt Rundungsfehler(?).
        note.value *= 0.9 if i.zero? 
        note.offset += teil * i
      }
    end    
  end
end
