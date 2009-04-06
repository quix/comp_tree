require File.dirname(__FILE__) + "/common"

class TestException < Test::Unit::TestCase
  def test_exception
    test_error = Class.new StandardError
    [true, false].each { |define_all|
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
      
            driver.compute(:area, 99) 
          }
          nil
        rescue => e
          e
        end
      )

      if define_all
        assert_block { error.is_a? test_error }
      else
        assert_block { error.is_a? CompTree::NoFunctionError }
      end
    }
  end
end 
