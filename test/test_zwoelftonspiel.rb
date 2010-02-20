# encoding: UTF-8

require 'test/unit'

$LOAD_PATH << File.dirname(__FILE__) + '/../lib'
require 'hauer/zwoelftonspiel'
require 'hauer/utils'
include Hauer::Utils

class TestZwoelftonspiel < Test::Unit::TestCase
  
  def setup  
    # Reihe aus J.M.H. Zwölftonspiel für Flöte und Cembalo vom 31. August 1948
    @spiel1 = Hauer::Zwoelftonspiel.new
    @spiel1.reihe = [71, 61, 62, 70, 68, 65, 63, 66, 69, 64, 60, 67]
    
    # Reihe aus J.M.H. Zwölftonspiel für Cembalo oder Klavier vom 11. Juni 1955 (Aus Sengstschmid)
    @spiel2 = Hauer::Zwoelftonspiel.new
    @spiel2.reihe = [57, 51, 48, 47, 55, 56, 49, 52, 46, 54, 53, 50]
  end
  
  def test_verwende_akkordkrebs
    krebs = @spiel1.klangreihe.reverse.rotate_right!
    assert @spiel1.verwende_akkordkrebs = true
    assert @spiel1.verwende_akkordkrebs?
    assert_equal(krebs, @spiel1.klangreihe)
  end
  
  def test_melodie_von_akkordkrebs
    @spiel1.verwende_akkordkrebs = true
    assert @spiel1.melodie
  end
  
  def test_melodie_von_akkordkrebs
    # vgl. http://www.musiker.at/sengstschmidjohann/stichwort-akkordkrebs.php3
    spiel = Hauer::Zwoelftonspiel.new
    spiel.reihe = %w(e g cis d b c f a fis dis h gis).map{|n| note2midi(n, :e)}
    spiel.verwende_akkordkrebs = true
    # Teste Gattung 1…
    assert_equal(%w(e fis a c d f g e b h cis dis), spiel.melodie(:flach => true, :gattung => 1).map{|n| midi2note(n)})    
  end
  
  def test_tonumfang_analog_zu_dreitongruppen
    assert_equal(0, @spiel1.umkehrung)
    assert_equal(@spiel1.tonumfang.to_a, @spiel1.dreitongruppen.flatten)
  end
  
  def test_umkehrung_aendert_dreitongruppen
    spiel = Hauer::Zwoelftonspiel.new    
    spiel.reihe = (0..11).to_a
    assert_equal(spiel.dreitongruppen.flatten, spiel.reihe)
    spiel.umkehrung = 1
    assert_equal(1, spiel.umkehrung)
    # umkehrung bedeutet rotation der inhalte der dreitongruppen nach rechts
    assert_equal(spiel.dreitongruppen.flatten, [11, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10])
  end
  
  # Melodie / Monophonie tests…
  
  def test_monophonie_erster_gattung_ist_gleich_reihe
    assert_equal(@spiel1.reihe, @spiel1.melodie(:gattung => 1))
  end
  
  def test_monophonie_zweiter_gattung
    assert_equal([
      [57, 50], [51, 46], [48], [47, 57], [55], [56, 51], [49, 53], [52, 47], [46, 52], [54], [53, 49], [50, 56]
      ], @spiel2.melodie(:gattung => 2, :flach => false))
  end
  
  def test_monophonie_dritter_gattung
    assert_equal([          
      [57, 53, 50], 
      [51, 53, 46], 
      [48, 51, 48],       
      [47, 51, 57],       
      [55, 53, 55],       
      [56, 53, 51], 
      [49, 47, 53], 
      [52, 49, 47], 
      [46, 49, 52],       
      [54, 56, 54],       
      [53, 46, 49],      
      [50, 53, 56]
      ], @spiel2.melodie(:gattung => 3, :flach => false))
  end
  
  def test_monophonie_vierter_gattung    
    assert_equal([          
      [57, 46, 53, 50], 
      [51, 53, 57, 46], 
      [48, 51, 53, 48],       
      [47, 51, 53, 57],       
      [55, 53, 51, 55],       
      [56, 47, 53, 51], 
      [49, 47, 56, 53], 
      [52, 49, 56, 47], 
      [46, 49, 56, 52],       
      [54, 56, 49, 54],       
      [53, 46, 56, 49],      
      [50, 46, 53, 56]              
      ], @spiel2.melodie(:gattung => 4, :flach => false))
  end
  
  def test_monophonie_fuenfter_gattung   
    # vgl. http://www.klangreihenmusik.at/skriptum-rekonstruktion-09.php3     
    assert_equal([
      [50], 
      [51, 46], 
      [48],
      [47, 51, 53, 57],
      [55],
      [56, 53, 51],
      [49, 53],
      [52, 49, 47],
      [46, 49, 52], 
      [54],
      [53, 49],
      [50, 53, 56]
      ], @spiel2.melodie(:gattung => 5, :flach => false))
  end
  
  def test_kontinuum_alias_klangreihe    
    assert_equal([
      [60, 64, 67, 71], 
      [61, 64, 67, 71], 
      [62, 64, 67, 71], 
      [62, 64, 67, 70], 
      [62, 64, 68, 70], 
      [62, 65, 68, 70], 
      [62, 63, 68, 70], 
      [62, 63, 66, 70], 
      [62, 63, 66, 69], 
      [62, 64, 66, 69], 
      [60, 64, 66, 69], 
      [60, 64, 67, 69]
      ], @spiel1.kontinuum)
      
    assert_equal(@spiel1.kontinuum, @spiel1.klangreihe)
      
    assert_equal([
      [46, 50, 53, 57], 
      [46, 51, 53, 57], 
      [48, 51, 53, 57], 
      [47, 51, 53, 57],       
      [47, 51, 53, 55],       
      [47, 51, 53, 56], 
      [47, 49, 53, 56], 
      [47, 49, 52, 56], 
      [46, 49, 52, 56],       
      [46, 49, 54, 56],             
      [46, 49, 53, 56],       
      [46, 50, 53, 56]
      ], @spiel2.kontinuum)
  end
  
  def test_neu
    z = Hauer::Zwoelftonspiel.new
    assert_equal(12, z.reihe.length)
    assert_equal(12, z.klangreihe.length)
  end    
end