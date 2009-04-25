
require 'comp_tree/queue'

module CompTree
  module Algorithm
    module_function

    def compute_parallel(root, num_threads)
      to_workers = Queue.new
      from_workers = Queue.new

      node_to_worker = nil
      node_from_worker = nil

      num_working = 0
      finished = nil

      workers = (1..num_threads).map {
        Thread.new {
          until (node = to_workers.pop) == nil
            node.compute
            from_workers.push node
          end
        }
      }

      Thread.new {
        while true
          if num_working == num_threads or
              not (node_to_worker = find_node(root))
            #
            # maxed out or no nodes available -- wait for results
            #
            node_from_worker = from_workers.pop
            node_from_worker.unlock
            num_working -= 1
            if node_from_worker == root or
                node_from_worker.computed.is_a? Exception
              finished = node_from_worker
              break
            end
          elsif node_to_worker
            #
            # found a node
            #
            to_workers.push node_to_worker
            num_working += 1
            node_to_worker = nil
          end
        end
        num_threads.times { to_workers.push nil }
      }.join

      workers.each { |t| t.join }
      
      if finished.computed.is_a? Exception
        raise finished.computed
      else
        finished.result
      end
    end

    def find_node(node)
      if node.computed
        #
        # already computed
        #
        nil
      elsif not node.locked? and node.children_results
        #
        # Node is not computed, not locked, and its children are
        # computed; Ready to compute.
        #
        node.lock
        node
      else
        #
        # locked or children not computed; recurse to children
        #
        node.each_child { |child|
          found = find_node(child) and (
            return found
          )
        }
        nil
      end
    end
  end
end
