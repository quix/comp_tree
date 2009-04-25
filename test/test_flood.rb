require File.dirname(__FILE__) + '/common'

class TestFlood < Test::Unit::TestCase
  def test_thread_flood
    (1..200).each { |num_threads|
      CompTree.build { |driver|
        noop = lambda { |*args| true }
        driver.define(:a, :b, &noop)
        driver.define(:b, &noop)
        driver.compute(:a, num_threads)
      }
    }
  end
end
