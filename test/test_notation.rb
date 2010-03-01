# encoding: UTF-8

require 'test/unit'

$LOAD_PATH << File.dirname(__FILE__) + '/../lib'
require 'hauer/notation'
class TestNotation < Test::Unit::TestCase
  include Hauer::Notation
  
  def test_note
    assert n = Note(60, 1)
    assert_equal(60, n.pitch)  
  end
  
  def test_default_value
    assert_equal(1.0, Note(60, 1).value)
  end
  
  def test_note_value
    n = Note(60, 0.5)
    assert_equal(0.5, n.value)
  end
  
  def test_default_velocity
    assert_equal(80, Note(60, 1).velocity)
  end
  
  def test_velocity
    assert_equal(90, Note(60, 1, :velocity => 90).velocity)
  end
  
  # TODO Klangreihe / Bassakkorde spielen
  # def test_enumerable_note
  # end
end
