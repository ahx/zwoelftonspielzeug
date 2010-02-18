# encoding: UTF-8
# Ein Zwölftonspielgenerator (nach Joseph Matthias Hauer)
# Language: German

require File.dirname(__FILE__) + '/core_ext'

# Joseph Matthias Hauer ist der ursprüngliche Erfinder der Zwölftonmusik
module Hauer
  module Lint
    def reihe_ok?(reihe)
      reihe.length == 12 &&
      reihe.uniq!.nil?   &&
      reihe.max - reihe.min == 11
    end
    module_function :reihe_ok?
  end

  # Konzipierung eines Zwölftonspiels
  # Siehe Sengstschmid http://www.klangreihenmusik.at/skriptum-rekonstruktion-01kl.php3
  # Siehe auch Götte, S.111 ff
  # Ruby 1.8.(7) does not like ö, so we use oe :(
  class Zwoelftonspiel
    attr_accessor :reihe
    
    def initialize
      # Das sind Midi-Töne. Es ginge auch 0..11, aber das wäre sehr tief.
      @reihe = (50..61).to_a      
    end
    
    # Eine nach Dreitongruppen erstellte Klangreihe
    # TODO Klangreihe mit großem Dur-Septakkord am Anfang generieren?! (vgl. Götte)
    def klangreihe      
      kamm = Array.new(4)
      # Jedem Reihenton einer Schicht (= Position im Akkord) zuweisen
      @reihe.map { |note|
        # Schichten (Dreitongruppen) durchlaufen…
        chromatische_dreitongruppen.each_with_index { |schicht, schicht_i|           
          if schicht.include?(note)
            kamm[schicht_i] = note            
            break
          end
        }
        kamm.dup        
      # Akkord-leerstellen auffüllen und sortieren
      }.each { |akkord|
        next(akkord) unless akkord.include?(nil)
        _array_spachteln!(akkord, kamm)
        akkord.sort!
      }
    end
    alias_method :kontinuum, :klangreihe      
    
    # Die aus der klangreihe automatisch abgeleitete Melodie
    # Auch Monophonie genannt
    def melodie(opt = {})
      opt = {
        #  Wenn false "gattung 2. Gattung", 
        :zwischenschritte => true, 
        :flach => true,
        :gattung => 5
      }.merge!(opt)
      
      melo = []
      akkorde = self.klangreihe
      reihe = @reihe
      # FIXME Wie wir hier vom zweiten einmal rum bis zum ersten Akkord laufen ist etwas komisch, aber ok.
      (1-akkorde.length..0).each_with_index { |akkord_i, i|
        prekord = akkorde[akkord_i-1]
        akkord = akkorde[akkord_i]
        # Zwölf- und Wendeton bestimmen die "Flusslage" (V. Sokolowski)
        zwoelfton_i = prekord.index(reihe[i])
        wendeton_i = prekord.index((prekord - akkord).first)
        zwoelfton = prekord[zwoelfton_i]
        wendeton = prekord[wendeton_i]
        achsentoene = prekord - [prekord[zwoelfton_i], prekord[wendeton_i]]
        case opt[:gattung]
        when 1
          # 1. Gattung ist die Zwölftonreihe und eher theoretischer Natur
          return opt[:flach] ? @reihe : @reihe.map{|n| [n]} 
        when 2
          # Ein Zwölfton + ein Achsenton + ein Wendeton
          # FIXME uniq macht es kurz, aber etwas kryptisch
          melo << [zwoelfton, wendeton].uniq
        when 3
          # 3. Gattung: ein Zwölfton + ein Achsenton + ein Wendeton
          achsenton = _finde_achsenton(achsentoene, zwoelfton, wendeton)
          melo << [zwoelfton, achsenton, wendeton]
        when 4
          # 4. Gattung: ein Zwölfton + zwei Achsentöne + ein Wendeton
          # Hier nehmen wir einfach die Achsentöne von unten nach oben oder 
          # die nächsten beiden, wenn es drei gibt
          achsentoene = _naehe_sortiert(achsentoene, zwoelfton) if wendeton == zwoelfton
          melo << [zwoelfton, achsentoene[0], achsentoene[1], wendeton]
        when 5
          # Bei der Methode mit den Zwischenschritten (bei Götte Gattung 5) vermag man "durchaus gleich mit dem 1. Sekundenschritt" beginnen (Sengstschmid)          
          (melo << [prekord[wendeton_i]]) and next if i.zero? 
          melo << prekord.values_at(*_von_bis(zwoelfton_i, wendeton_i).to_a)
        else 
         raise ArgumentError.new("Ich kenne keine Gattung #{opt[:gattung]}! Optionen: #{opt.inspect}")
        end
      }
      return melo.flatten if opt[:flach]
      melo
    end
    
    def reihe_ok?
      Hauer::Lint.reihe_ok?(self.reihe)
    end
    
    def chromatische_dreitongruppen
      (@reihe.min..(@reihe.min+11)).to_a.in_groups(4)
    end
    
    def _finde_achsenton(achsentoene, zwoelfton, wendeton)
      # FIXME Bei der 3. und 4. Gattung gibt es zwei wege in welcher Reihenfolge die Achsentöne gespielt werden (siehe Tabelle von Sokolowski, Götte S.125)      
      # Hier wollen wir, wie bei der 2. Gattung) große Tonschritte möglichst 
      if zwoelfton == wendeton
        return _naehe_sortiert(achsentoene, zwoelfton).first
      end
      zt_bis_wt = [zwoelfton, wendeton].sort          
      achsentoene.each { |n| return n if n.between?(*zt_bis_wt) }
      # …und gehen wenn sonst von unten nach oben      
      achsentoene.first
    end
    
    def _naehe_sortiert(werte, ziel)
      werte.sort{ |a,b| (a - ziel).abs <=> (b - ziel).abs }
    end
    
    # Leider geht sowas wie [1,2,3][(-3..0)] nicht. Deshalb zählen wir runter oder rauf.          
    def _von_bis(von, bis, &block)
      richtung = von > bis ? -1 : 1
      von.step(bis, richtung, &block)
    end
    
    def _array_spachteln!(array, spachtel)
      array.each_with_index { |value, index|
        array[index] = spachtel[index] if value.nil?
      }
    end
  end
end
