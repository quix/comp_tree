require File.dirname(__FILE__) + '/common'

class TestGrind < Test::Unit::TestCase
  include TestCommon

  GENERATOR_DATA = {
    :level_range => 1..5,
    :children_range => 1..5,
    :thread_range => 1..10,
    :drain_iterations => 30,
  }

  ROOT = 'a'
  RETURN_FLAG = rand

  def test_grind
    run_generated_tree(GENERATOR_DATA)
  end

  def generate_comp_tree(num_levels, num_children, drain_iterations)
    CompTree.build { |driver|
      name_gen = ROOT.dup
      pick_names = lambda { |*args|
        (0..rand(num_children)).map {
          name_gen.succ!
          name_gen.dup
        }
      }
      drain = lambda { |*args|
        drain_iterations.times {
        }
        RETURN_FLAG
      }
      build_tree = lambda { |parent, children, level|
        #trace "building #{parent} --> #{children.join(' ')}"
        
        driver.define(parent, *children, &drain)

        if level < num_levels
          children.each { |child|
            build_tree.call(child, pick_names.call, level + 1)
          }
        else
          children.each { |child|
            driver.define(child, &drain)
          }
        end
      }
      build_tree.call(ROOT, pick_names.call, 0)
      driver
    }
  end

  def run_generated_tree(args)
    args[:level_range].each { |num_levels|
      args[:children_range].each { |num_children|
        separator
        bench_output {%{num_levels}}
        bench_output {%{num_children}}
        driver = generate_comp_tree(
          num_levels,
          num_children,
          args[:drain_iterations])
        args[:thread_range].each { |threads|
         bench_output {%{threads}}
          2.times {
            driver.reset(ROOT)
            result = nil
            bench = Benchmark.measure {
              result = driver.compute(ROOT, threads)
            }
            bench_output bench
            assert_equal(result, RETURN_FLAG)
          }
        }
      }
    }
  end
end
