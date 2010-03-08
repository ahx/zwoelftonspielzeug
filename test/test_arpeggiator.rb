# encoding: UTF-8

require 'test/unit'

$LOAD_PATH << File.dirname(__FILE__) + '/../lib'
require 'hauer/notation'
require 'hauer/arpeggiator'

class TestArpeggiator < Test::Unit::TestCase
  include Hauer::Notation

  def setup
    @noten = [Note(60, 1), Note(64, 1), Note(68, 1)]
    teil = 1.0 / 3
    @arp = [
      Note(60, 1*0.9), # TODO Weg damit
      Note(64, 1 - teil, :offset => teil),
      Note(68, 1 - teil*2, :offset => teil*2)
      ]
  end
  
  def test_arpeggiator
    Hauer::Arpeggiator.arpeggio!(@noten)
    assert_equal(@arp, @noten)
    # TODO test arp
    assert Hauer::Arpeggiator.arpeggio!(@noten, :arp => 0.1)
  end
  
  def test_nested
    # test nested
    Hauer::Arpeggiator.arpeggio!([@noten])
    assert_equal([@arp], [@noten])
  end
end