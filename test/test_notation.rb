# encoding: UTF-8

require 'test/unit'

$LOAD_PATH << File.dirname(__FILE__) + '/../lib'
require 'hauer/notation'
class TestNotation < Test::Unit::TestCase
  include Hauer::Notation
  
  def test_note
    assert n = Note(60, 1)
    assert n.value.is_a?(Float), "value should be a Float. is: #{n.value.inspect}"
    assert_equal(60, n.pitch)  
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
    
  def test_minus
    note = Note(60, 1)
    # Eine Oktave nach unten
    note = note - 12
    assert_equal(48, note.pitch)
  end
  
  def test_plus
    note = Note(60, 1)
    # Eine Oktave nach unten
    note = note + 12
    assert_equal(72, note.pitch)
  end
    
  def test_offset
    assert_equal(0, Note(60, 1).offset) # default
    assert_equal(0.25, Note(60, 1, :offset => 0.25).offset)
  end
end
