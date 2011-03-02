require File.expand_path(File.dirname(__FILE__)) + '/comp_tree_test_base'

class FloodTest < CompTreeTest
  def test_thread_flood
    (0..200).each { |num_threads|
      CompTree.build { |driver|
        noop = lambda { |*args| true }
        driver.define(:a, :b, &noop)
        driver.define(:b, &noop)
        driver.compute(:a, num_threads)
      }
    }
  end
end
