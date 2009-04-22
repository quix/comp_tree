
module CompTree
  # Base class for CompTree errors.
  class Error < StandardError ; end
    
  #
  # Attempt to redefine a Node.
  #
  # If you wish to only replace the function, set
  #   driver.nodes[name].function = lambda { ... }
  #
  class RedefinitionError < Error ; end
  
  # Encountered a node without a function during a computation.
  class NoFunctionError < Error ; end
end
