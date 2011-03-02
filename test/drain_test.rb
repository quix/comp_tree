require File.expand_path(File.dirname(__FILE__)) + '/comp_tree_test_base'

class DrainTest < CompTreeTest
  def drain
    500000.times { }
  end
  
  def run_drain(threads)
    CompTree.build { |driver|
      func = lambda { |*args|
        drain
      }
      driver.define(:area, :width, :height, :offset, &func)
      driver.define(:width, :border, &func)
      driver.define(:height, :border, &func)
      driver.define(:border, &func)
      driver.define(:offset, &func)
      bench_output "number of threads: #{threads}"
      bench = Benchmark.measure { driver.compute(:area, threads) }
      bench_output bench
    }
  end

  def each_drain
    (0..10).each { |threads|
      yield threads
    }
  end

  def test_drain
    separator
    each_drain { |threads|
      run_drain(threads)
    }
  end
end
