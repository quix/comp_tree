require File.expand_path(File.dirname(__FILE__)) + '/comp_tree_test_base'

class ExceptionTest < CompTreeTest
  def test_exception
    test_error = Class.new StandardError
    [true, false].each { |define_all|
      [true, false].each { |abort_on_exception|
        (1..20).each { |num_threads|
          error = (
            begin
              CompTree.build { |driver|
                driver.define(:area, :width, :height, :offset) {
                  |width, height, offset|
                  width*height - offset
                }
                
                driver.define(:width, :border) { |border|
                  2 + border
                }
    
                driver.define(:height, :border) { |border|
                  3 + border
                }
                
                if define_all
                  driver.define(:border) {
                    raise test_error
                  }
                end
                
                driver.define(:offset) {
                  7
                }
          
                begin
                  previous = Thread.abort_on_exception
                  Thread.abort_on_exception = abort_on_exception
                  driver.compute(:area, num_threads) 
                ensure
                  Thread.abort_on_exception = previous
                end
              }
              nil
            rescue Exception => e
              e
            end
          )
    
          if define_all
            assert_block { error.is_a? test_error }
          else
            assert_block { error.is_a? CompTree::NoFunctionError }
            assert_equal(
              "no function was defined for node `:border'",
              error.message
            )
          end
        }
      }
    }
  end 

  def test_num_threads
    CompTree.build do |driver|
      driver.define(:root) { }
      assert_raises(RangeError) { driver.compute(:root, 0) }
      assert_raises(RangeError) { driver.compute(:root, -1) }
      assert_raises(RangeError) { driver.compute(:root, -11) }

      assert_raises(TypeError) { driver.compute(:root, "11") }
      assert_raises(TypeError) { driver.compute(:root, {}) }
      assert_raises(TypeError) { driver.compute(:root, Object.new) }
      assert_raises(TypeError) { driver.compute(:root, true) }
      assert_raises(TypeError) { driver.compute(:root, nil) }
    end
  end

  def test_invalid_node
    (1..20).each { |num_threads|
      CompTree.build do |driver|
        driver.define(:root) { }
        driver.compute(:root, num_threads)

        error = assert_raises(CompTree::NoNodeError) {
          driver.compute(:a, num_threads)
        }
        assert_equal "no node named `:a'", error.message
        assert_equal :a, error.node_name

        error = assert_raises(CompTree::NoNodeError) {
          driver.compute(nil, num_threads)
        }
        assert_equal nil, error.node_name
        assert_equal "no node named `nil'", error.message
        assert_equal "#<CompTree::NoNodeError: #{error.message}>", error.inspect
      end
    }
  end

  def test_missing_function
    (1..20).each { |num_threads|
      CompTree.build { |driver|
        driver.define(:f, :x) { |x|
          x + 33
        }
        error = assert_raises(CompTree::NoFunctionError) {
          driver.compute(:f, num_threads)
        }
        msg = "no function was defined for node `:x'"
        assert_equal msg, error.message
        assert_equal "#<CompTree::NoFunctionError: #{msg}>", error.inspect
      }
    }
  end
end
