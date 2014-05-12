require File.expand_path(File.dirname(__FILE__)) + '/comp_tree_test_base'

class ThrowTest < CompTreeTest
  EXPECTED = RUBY_VERSION >= "1.9.0" ? ArgumentError : ThreadError

  def test_throw
    init_size = Thread.list.size
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
    assert_equal init_size, Thread.list.size
  end
end
