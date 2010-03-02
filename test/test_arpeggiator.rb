# encoding: UTF-8

require 'test/unit'

$LOAD_PATH << File.dirname(__FILE__) + '/../lib'
require 'hauer/notation'
require 'hauer/arpeggiator'

class TestArpeggiator < Test::Unit::TestCase
  include Hauer::Notation
  
  def test_arpeggiator
    noten = [Note(60, 1), Note(64, 1), Note(68, 1)]
    Hauer::Arpeggiator.arpeggio!(noten)
    teil = 1.0 / 3
    assert_equal([
      Note(60, 1*0.9), # TODO Weg damit
      Note(64, 1 - teil, :offset => teil),
      Note(68, 1 - teil*2, :offset => teil*2)
      ], noten)
  end
end