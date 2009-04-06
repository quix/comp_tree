require File.dirname(__FILE__) + "/common"

class TestBasic < Test::Unit::TestCase
  def test_define
    (1..20).each { |threads|
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
        
        driver.define(:offset) {
          7
        }
        
        assert_equal((2 + 5)*(3 + 5) - 7, driver.compute(:area, threads))
      }
    }
  end

  def test_already_computed
    [nil, false, true, 33].each { |result|
      CompTree.build { |driver|
        driver.define(:a) { result }
        (1..3).each { |n|
          assert_equal(result, driver.compute(:a, n))
        }
      }
    }
  end

  def test_threads_opt
    (1..20).each { |threads|
      CompTree.build do |driver|
        driver.define(:a) { 33 }
        assert_equal(33, driver.compute(:a, :threads => threads))
      end
    }
  end

  def test_malformed
    CompTree.build { |driver|
      assert_raise(CompTree::ArgumentError) {
        driver.define {
        }
      }
      assert_raise(CompTree::RedefinitionError) {
        driver.define(:a) {
        }
        driver.define(:a) {
        }
      }
      assert_raise(CompTree::ArgumentError) {
        driver.define(:b) {
        }
        driver.compute(:b, 0)
      }
      assert_raise(CompTree::ArgumentError) {
        driver.define(:c) {
        }
        driver.compute(:c, -1)
      }
    }
  end

  def test_exception_in_compute
    test_error = Class.new(RuntimeError)
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
        raise test_error
      }
      
      driver.define(:offset) {
        7
      }
      
      assert_raise(test_error) {
        driver.compute(:area, 6)
      }
    }
  end

  def test_node_subclass
    data = Object.new
    subclass = Class.new(CompTree::Node) {
      define_method :stuff do
        data
      end
    }
    CompTree.build(:node_class => subclass) { |driver|
      driver.define(:a) { }
      assert_equal(data, driver.nodes[:a].stuff)
    }
  end

  def test_non_symbols
    width_id = Object.new
    height_id = 272727
    (1..3).each { |threads|
      CompTree.build { |driver|
        driver.define("area", width_id, height_id, :offset) {
          |width, height, offset|
          width*height - offset
        }
          
        driver.define(width_id, :border) { |border|
          2 + border
        }
          
        driver.define(height_id, :border) { |border|
          3 + border
        }
          
        driver.define(:border) {
          5
        }
          
        driver.define(:offset) {
          7
        }
          
        assert_equal((2 + 5)*(3 + 5) - 7, driver.compute("area", threads))
      }
    }
  end

  def test_node_name_equality_comparison
    CompTree.build { |driver|
      driver.define("hello") { }
      assert_raise(CompTree::RedefinitionError) {
        driver.define("hello") { }
      }
    }
  end
  
  def test_result_variety
    [true, false, nil, Object.new, 33].each { |result|
      (1..20).each { |threads|
        CompTree.build { |driver|
          driver.define(:area, :width, :height, :offset) {
            |width, height, offset|
            result
          }
          
          driver.define(:width, :border) { |border|
            result
          }
          
          driver.define(:height, :border) { |border|
            result
          }
          
          driver.define(:border) {
            result
          }
          
          driver.define(:offset) {
            result
          }
          
          assert_equal(result, driver.compute(:area, threads))
        }
      }
    }
  end
end
