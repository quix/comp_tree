require File.dirname(__FILE__) + "/common"

class TestSequential < Test::Unit::TestCase
  def test_sequential
    (1..50).each { |num_threads|
      [1, 2, 3, 20, 50].each { |num_nodes|
        CompTree.build { |driver|
          driver.define(:root) { true }
          (1..num_nodes).each { |n|
            if n == 0
              driver.define("a#{n}".to_s, :root) { true }
            else
              driver.define("a#{n}".to_s, "a#{n-1}".to_s) { true }
            end
          }
          driver.compute(:root, num_threads)
        }
      }
    }
  end
end
