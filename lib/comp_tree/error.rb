
module CompTree
  #
  # Base class for CompTree errors.
  #
  class Error < StandardError
    def inspect  #:nodoc:
      "#<#{self.class.name}: #{message}>"
    end
  end

  #
  # Base class for node errors.
  #
  class NodeError < Error
    attr_reader :node_name
    
    def initialize(node_name)  #:nodoc:
      super()
      @node_name = node_name
    end
  end
    
  #
  # An attempt was made to redefine a node.
  #
  # If you wish to only replace the function, set
  #   driver.nodes[name].function = lambda { ... }
  #
  class RedefinitionError < NodeError
    def message  #:nodoc:
      "attempt to redefine node `#{node_name.inspect}'"
    end
  end
  
  #
  # Encountered a node without a function during a computation.
  #
  class NoFunctionError < NodeError
    def message  #:nodoc:
      "no function was defined for node `#{node_name.inspect}'"
    end
  end

  #
  # Requested node does not exist.
  #
  class NoNodeError < NodeError
    def message  #:nodoc:
      "no node named `#{node_name.inspect}'"
    end
  end
end
