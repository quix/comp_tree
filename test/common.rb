$LOAD_PATH.unshift File.dirname(__FILE__) + '/../lib'

require 'test/unit'
require 'comp_tree'
#require 'benchmark'

module TestCommon
  if ARGV.include?("--bench")
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
    def separator() end
    def bench_output(desc = nil, stream = STDOUT, &block) end
  end
end
