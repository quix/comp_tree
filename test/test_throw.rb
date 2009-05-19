require File.dirname(__FILE__) + '/common'

class TestThrow < Test::Unit::TestCase
  EXPECTED = RUBY_VERSION >= "1.9.0" ? ArgumentError : ThreadError

  def test_throw
    assert_equal 1, Thread.list.size
    exception = assert_raises(EXPECTED) {
      CompTree.build do |driver|
        driver.define(:root, :a) {
          loop { }
        }
        driver.define(:a) {
          throw :outta_here
        }
        driver.compute(:root, 10)
      end
    }
    assert_match "uncaught", exception.message
    assert_equal 1, Thread.list.size
  end
end
