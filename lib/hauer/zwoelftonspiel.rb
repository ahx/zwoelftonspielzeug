# encoding: UTF-8
# Ein Zwölftonspielgenerator (nach Joseph Matthias Hauer)
# Language: German

$LOAD_PATH.unshift File.dirname(__FILE__) + '/..'
require 'hauer/core_ext'
require 'hauer/notation'

# TODO Schlusston bei Akkordkrebs noch mal Nachschlagen
# TODO Lambdoma, Stimmvertauschung (?)

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

  require 'observer'
  # Konzipierung eines Zwölftonspiels
  # Siehe Sengstschmid http://www.klangreihenmusik.at/skriptum-rekonstruktion-01kl.php3
  # Siehe auch Götte, S.111 ff
  # Ruby 1.8.(7) does not like ö, so we use oe :(
  class Zwoelftonspiel
    class Takt < Struct.new(:zaehler, :nenner)
      def laenge
        zaehler / nenner
      end
      
      # Länge eines Schlages
      def schlag
        1.0 / nenner
      end
      
      def betont?(schlagzeit)
        schlagzeit.zero?
      end
    end
    
    include Hauer::Notation
    include Observable  
    include ObservableAccessor
    observable_accessor :reihe    
    # Bei der "Umkehrung" werden die Inhalte der Dreitongruppen / Quadranten verschoben.
    # Umkehrung 0 bedeutet, die Dreitongruppen sind analog zum Tonumfang / zur sortieren Reihe
    # Umkehrung 1..11 bedeutet, dass die Noten über die Quadranten um n nach rechts rotiert werden
    # Umkehrung 12 ist logischer weise gleich mit Umkehrung 0. 13 mit 1 etc.
    observable_accessor :umkehrung
    # Durch die (virtuelle) Transposition der Reihe wird die Klangreihe/Melodie transponiert. Siehe reihe
    observable_accessor :transposition
    # Akkordkrebs verwenden (true / false)
    observable_accessor :akkordkrebs
    attr :takt
    def akkordkrebs?; akkordkrebs; end      
    
    def initialize
      # Das sind Midi-Töne. Es ginge auch 0..11, aber das wäre sehr tief.
      @reihe = (50..61).to_a  # FIXME use 0..11 ?
      @umkehrung = 0
      @akkordkrebs = false
      @transposition = 0
      # Wir benutzen einen Dreivierteltakt
      @takt = Takt.new(3.0, 4.0)
    end
    
    # Keiner liest @reihe alle lesen reihe !
    def reihe
      @reihe.map{|n| n + @transposition}
    end

    # Rhythmisiert die Töne der melodie und gibt Note-Instanzen zurück.
    def melodie_notation(array)
      noten = []
      array.each {|k| 
        klang = Array(k)
        klang.each_with_index { |note, schlagzeit|
          # TODO Sonderfall (optional, togglebar): punktierte Achtel + Sechszehntel Note if klang.length == 1
          wert =  @takt.laenge / klang.length
          note = Hauer::Notation.Note(note, wert) 
          note.velocity = 92 if @takt.betont?(schlagzeit)
          noten << note
        }        
      }
      noten
    end
    
    # Eine nach Dreitongruppen erstellte Klangreihe
    # FIXME refactor
    # TODO Klangreihe mit großem Dur-Septakkord am Anfang generieren?! (vgl. Götte)
    def klangreihe
      kamm = Array.new(4)
      # Jedem Reihenton einer Schicht (= Position im Akkord) zuweisen
      k = reihe.map { |note|
        # Schichten (Dreitongruppen) durchlaufen…
        dreitongruppen.each_with_index { |schicht, schicht_i|           
          if schicht.include?(note)
            kamm[schicht_i] = note
            break
          end
        }
        kamm.dup        
      # Akkord-leerstellen auffüllen und sortieren
      }
      k.each { |akkord|
        next(akkord) unless akkord.include?(nil)        
        _array_spachteln!(akkord, kamm)
        # Note(akkord, @takt.laenge)
      }
      k.map! {|akkord|
        akkord.map{|note| Note(note, @takt.laenge)}
      }
      # TODO Bei Akkordkrebs mit dem 1. Akkord der ursprünglichen Klangreihe beginnen??
      k.reverse!.rotate_right! if akkordkrebs?
      k
    end
    alias_method :kontinuum, :klangreihe
    
    # Die aus der klangreihe automatisch abgeleitete Melodie
    # Auch Monophonie genannt
    # FIXME refactor
    def melodie(opt = {})
      opt = {
        :gattung => 5    
      }.merge!(opt)      
      melo = []
      akkorde = self.klangreihe.map {|a| a.map(&:pitch)}
      # FIXME Wie wir hier vom zweiten einmal rum bis zum ersten Akkord laufen ist komisch.
      (1-akkorde.length..0).each_with_index { |akkord_i, i|
        prekord = akkorde[akkord_i-1] # startet bei [0]
        akkord = akkorde[akkord_i]    # startet bei [1]
        # Zwölf- und Wendeton bestimmen die "Flusslage" (V. Sokolowski)
        # Beim Akkordkrebs ist der (neue) Reihenton, der Wendeton vom Prekord nach davor
        # Beim ersten Akkord wird der Normale Reihenton verwendet
        if akkordkrebs? && !i.zero?
          zwoelfton = _wendeton_von_nach(prekord, akkorde[i-1]).first
        else
          zwoelfton = reihe[i]
        end
        wendeton = _wendeton_von_nach(prekord, akkord).first
        achsentoene = prekord - [zwoelfton, wendeton]
        case opt[:gattung]
        when 1
          # 1. Gattung ist die Zwölftonreihe und eher theoretischer Natur
          # Falls der Akkordkrebs verwendet wird, können wir hier aber nicht direkt die reihe zurückgeben,
          # deshalb machen wir das der konsequenter weise per Hand…
          melo << [zwoelfton]
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
          # Bei der Methode mit den Zwischenschritten (zt + at dazwischen + wendeton) (bei Götte Gattung 5) vermag man "durchaus gleich mit dem 1. Sekundenschritt" beginnen (Sengstschmid)          
          melo << [wendeton] and next if i.zero? 
          melo << [zwoelfton] and next if wendeton == zwoelfton
          dazwischen = achsentoene.select { |n| n.between?(*[zwoelfton, wendeton].sort) }
          melo << [zwoelfton] + dazwischen + [wendeton]
        else 
         raise ArgumentError.new("Ich kenne keine Gattung #{opt[:gattung]}! Optionen: #{opt.inspect}")
        end
      }
      melodie_notation melo
    end
    
    def reihe_ok?
      Hauer::Lint.reihe_ok?(self.reihe)
    end
    
    def tonumfang
      (reihe.min..(reihe.min+11))
    end
    
    def dreitongruppen
      tonumfang.to_a.rotate_right!(self.umkehrung).in_groups(4)
    end
    
    def _wendeton_von_nach(von, nach)
      von - nach
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
      array
    end
  end
end
