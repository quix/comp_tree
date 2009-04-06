require File.dirname(__FILE__) + "/common"

class TestCircular < Test::Unit::TestCase
  def test_circular
    CompTree.build { |driver|
      driver.define(:area, :width, :height, :offset) { |width, height, offset|
        width*height - offset
      }
      
      driver.define(:width, :border) { |border|
        2 + border
      }
      
      driver.define(:height, :border) { |border|
        3 + border
      }
      
      driver.define(:border) {
        5
      }
      
      driver.define(:offset, :area) {
        7
      }

      assert_raises(CompTree::CircularError) {
        driver.check_circular(:area)
      }
    }
  end
end
