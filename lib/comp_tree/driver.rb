
require 'comp_tree/algorithm'
require 'comp_tree/node'
require 'comp_tree/error'

module CompTree
  #
  # Driver is the main interface to the computation tree.  It is
  # responsible for defining nodes and running computations.
  #
  class Driver
    include Algorithm

    #
    # See CompTree.build
    #
    def initialize(opts = nil)  #:nodoc:
      @node_class =
        if opts and opts[:node_class]
          opts[:node_class]
        else
          Node
        end
      @nodes = Hash.new
    end

    #
    # Name-to-node hash.
    #
    attr_reader :nodes

    #
    # _name_ -- unique node identifier (for example a symbol).
    #
    # _child_names_ -- unique node identifiers of children.
    #
    # Define a computation node.
    #
    # During a computation, the results of the child nodes are passed
    # to the block.  The block returns the result of this node's
    # computation.
    #
    # In this example, a computation node named +area+ is defined
    # which depends on the nodes +width+ and +height+.
    #
    #   driver.define(:area, :width, :height) { |width, height|
    #     width*height
    #   }
    #
    def define(name, *child_names, &block)
      #
      # retrieve or create parent and children
      #

      parent = @nodes[name] || (@nodes[name] = @node_class.new(name))
      if parent.function
        raise RedefinitionError, "Node `#{parent.name.inspect}' redefined."
      end
      parent.function = block
      
      children = child_names.map { |child_name|
        @nodes[child_name] || (
          @nodes[child_name] = @node_class.new(child_name)
        )
      }

      #
      # link
      #
      parent.children = children
      children.each { |child|
        child.parents << parent
      }
    end

    #
    # _name_ -- unique node identifier (for example a symbol).
    #
    # Mark this node and all its children as uncomputed.
    #
    def reset(name)
      @nodes[name].reset
    end

    #
    # _name_ -- unique node identifier (for example a symbol).
    #
    # Check for a cyclic graph below the given node.  If found,
    # returns the names of the nodes (in order) which form a loop.
    # Otherwise returns nil.
    #
    def check_circular(name)
      helper = Proc.new { |root, chain|
        if chain.include? root
          return chain + [root]
        end
        @nodes[root].children.each { |child|
          helper.call(child.name, chain + [root])
        }
      }
      helper.call(name, [])
      nil
    end

    #
    # :call-seq:
    #   compute(name, threads)
    #   compute(name, :threads => threads)
    #
    # _name_ -- unique node identifier (for example a symbol).
    #
    # _threads_ -- number of threads.
    #
    # Compute this node, returning its result.
    #
    # Any uncomputed children are computed first.
    #
    def compute(name, opts)
      threads = (opts.is_a?(Hash) ? opts[:threads] : opts).to_i
      unless threads > 0
        raise ArgumentError, "number of threads must be greater than zero"
      end
      root = @nodes[name]
      if root.computed
        root.result
      elsif threads == 1
        root.result = root.compute_now
      else
        compute_parallel(root, threads)
      end
    end
  end
end
