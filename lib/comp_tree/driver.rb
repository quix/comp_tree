
require 'comp_tree/algorithm'
require 'comp_tree/node'
require 'comp_tree/error'

require 'thread'

module CompTree
  #
  # Driver is the main interface to the computation tree.  It is
  # responsible for defining nodes and running computations.
  #
  class Driver
    include Algorithm

    #
    # Build and run a new computation tree.
    #
    # If a block is passed, the new instance is passed to it.
    #
    # Options hash:
    #
    # <tt>:node_class</tt> -- (Class) CompTree::Node subclass from
    # which nodes are created.
    #
    def initialize(opts = nil)
      @node_class =
        if opts and opts[:node_class]
          opts[:node_class]
        else
          Node
        end

      @nodes = Hash.new

      if block_given?
        yield self
      end
    end

    #
    # Name-to-node hash.
    #
    attr_reader :nodes

    #
    # Define a computation node.
    #
    # The first argument is the name of the node to define.
    # Subsequent arguments are are the names of its children, which
    # are the inputs to this node.
    #
    # The input values are passed to the block.  The block returns the
    # result of this node.
    #
    # In this example, a computation node named +area+ is defined
    # which depends on the nodes +height+ and +width++.
    #
    #   driver.define(:area, :width, :height) { |width, height|
    #     width*height
    #   }
    #
    # NOTE: You must return a non-nil value to signal the computation
    # is complete.  If nil is returned, the node will be recomputed.
    #
    def define(*args, &block)
      parent_name = args.first
      children_names = args[1..-1]
      
      unless parent_name
        raise ArgumentError, "No name given for node"
      end
      
      #
      # retrieve or create parent and children
      #
      parent =
        if t = @nodes[parent_name]
          t
        else 
          @nodes[parent_name] = @node_class.new(parent_name)
        end

      if parent.function
        raise RedefinitionError, "Node #{parent.name} already defined."
      end
      parent.function = block
      
      children = children_names.map { |child_name|
        if t = @nodes[child_name]
          t
        else
          @nodes[child_name] = @node_class.new(child_name)
        end
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
    # Mark this node and all its children as uncomputed.
    #
    # Arguments:
    #
    # +name+ -- (Symbol) node name.
    #
    def reset(name)
      @nodes[name].reset
    end

    #
    # Check for a cyclic graph below the given node.  Raises
    # CompTree::CircularError if found.
    #
    # Arguments:
    #
    # +name+ -- (Symbol) node name.
    #
    def check_circular(name)
      helper = lambda { |root, chain|
        if chain.include? root
          raise CircularError,
            "Circular dependency detected: #{root} => #{chain.last} => #{root}"
        end
        @nodes[root].children.each { |child|
          helper.call(child.name, chain + [root])
        }
      }
      helper.call(name, [])
    end

    #
    # Compute this node.
    #
    # Arguments:
    #
    # +name+ -- (Symbol) node name.
    #
    # +threads+ -- (Integer) number of threads.
    #
    # compute(:volume, :threads => 4) syntax is also accepted.
    #
    def compute(name, opts)
      threads = (opts.respond_to?(:to_i) ? opts : opts[:threads]).to_i
      root = @nodes[name]

      if threads < 1
        raise ArgumentError, "threads is #{threads}"
      end

      if threads == 1
        root.result = root.compute_now
      else
        compute_multithreaded(root, threads)
      end
    end
  end
end
