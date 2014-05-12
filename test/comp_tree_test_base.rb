$LOAD_PATH.unshift File.dirname(__FILE__) + '/../lib'
$LOAD_PATH.unshift File.dirname(__FILE__) + '/../devel'

gem 'minitest'
require 'minitest/unit'
require 'minitest/autorun' unless defined? Rake
require 'comp_tree'

class CompTreeTest < MiniTest::Unit::TestCase
  if ARGV.include?("--bench")
    require 'benchmark'

    def separator
      puts
      puts "-"*60
    end

    def bench_output(desc = nil, stream = STDOUT, &block)
      if desc
        stream.puts(desc)
      end
      if block
        expression = block.call
        result = eval(expression, block.binding)
        stream.printf("%-16s => %s\n", expression, result.inspect)
        result
      end
    end
  else
    module Benchmark
      class << self
        def measure
          yield
        end
      end
    end

    def separator()
    end

    def bench_output(desc = nil, stream = STDOUT, &block)
    end
  end
end
