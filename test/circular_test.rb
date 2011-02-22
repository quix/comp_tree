require File.expand_path(File.dirname(__FILE__)) + '/comp_tree_test_base'

class CircularTest < CompTreeTest
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

      assert_equal([:area, :offset, :area], driver.check_circular(:area))
      assert_equal([:offset, :area, :offset], driver.check_circular(:offset))
    }
  end

  def test_not_circular
    CompTree.build { |driver|
      driver.define(:a, :b) { true }
      driver.define(:b) { true }
      assert_nil(driver.check_circular(:a))
      assert_nil(driver.check_circular(:b))
    }
  end
end
