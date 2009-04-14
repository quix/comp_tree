require File.dirname(__FILE__) + "/common"

class TestException < Test::Unit::TestCase
  def test_exception
    test_error = Class.new StandardError
    [true, false].each { |define_all|
      [true, false].each { |abort_on_exception|
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
                driver.compute(:area, 99) 
              ensure
                Thread.abort_on_exception = previous
              end
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
    }
  end 
end
