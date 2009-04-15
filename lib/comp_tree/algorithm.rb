
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
          until (node = to_workers.pop) == :finished
            node.compute
            from_workers.push node
          end
        }
      }

      while true
        if num_working == num_threads or not (node_to_worker = find_node(root))
          #
          # max computations running or no nodes available -- wait for results
          #
          node_from_worker = from_workers.pop
          node_from_worker.unlock
          num_working -= 1
          if node_from_worker == root or node_from_worker.computed.is_a? Exception
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
      
      num_threads.times { to_workers.push :finished }
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
        # Node is not computed and its children are computed;
        # and we have the lock.  Ready to compute.
        #
        node.lock
        node
      else
        #
        # locked or children not computed; recurse to children
        #
        node.each_child { |child|
          if found = find_node(child)
            return found
          end
        }
        nil
      end
    end
  end
end

__END__

#
#  For test_grind.rb the following multi-threaded-node-searching
#  algorithm was 3x faster than the old queuing algorithm above (using
#  the same srand, of course).  However it was discovered that when
#  drain_iterations is _increased_, both algorithms run _faster_ (!!!)
#  until drain_iterations reaches around 30.  The thread queuing
#  algorithm was better in the latter range, but not always.  More
#  investigation is needed.
# 

module CompTree
  module Algorithm
    LEAVE = :__comp_tree_leave
    AGAIN = :__comp_tree_again

    module_function

    def loop_with(leave, again)
      catch(leave) {
        while true
          catch(again) {
            yield
          }
        end
      }
    end

    def compute_parallel(root, num_threads)
      #trace "Computing #{root.name} with #{num_threads} threads"
      finished = nil
      tree_mutex = Mutex.new
      condition = ConditionVariable.new
      num_threads_ready = 0

      threads = (0...num_threads).map { |thread_index|
        Thread.new {
          #
          # wait for main thread
          #
          tree_mutex.synchronize {
            #trace "Thread #{thread_index} waiting to start"
            num_threads_ready += 1
            condition.wait(tree_mutex)
          }

          loop_with(LEAVE, AGAIN) {
            node = tree_mutex.synchronize {
              #trace "Thread #{thread_index} acquired tree lock; begin search"
              if finished
                #trace "Thread #{thread_index} detected finish"
                num_threads_ready -= 1
                throw LEAVE
              else
                #
                # Find a node.  The node we obtain, if any, will be locked.
                #
                node = find_node(root)
                if node
                  #trace "Thread #{thread_index} found node #{node.name}"
                  node
                else
                  #trace "Thread #{thread_index}: no node found; sleeping."
                  condition.wait(tree_mutex)
                  throw AGAIN
                end
              end
            }

            #trace "Thread #{thread_index} computing node"
            #debug {
            #  node.trace_compute
            #}
            node.compute
            #trace "Thread #{thread_index} node computed; waiting for tree lock"

            tree_mutex.synchronize {
              #trace "Thread #{thread_index} acquired tree lock"
              #debug {
              #  name = "#{node.name}" + ((node == root) ? " (ROOT NODE)" : "")
              #  initial = "Thread #{thread_index} compute result for #{name}: "
              #  status = node.computed.is_a?(Exception) ? "error" : "success"
              #  trace initial + status
              #  trace "Thread #{thread_index} node result: #{node.result}"
              #}

              if node.computed.is_a? Exception
                #
                # An error occurred; we are done.
                #
                finished = node.computed
              elsif node == root
                #
                # Root node was computed; we are done.
                #
                finished = true
              end
                
              #
              # remove locks for this node (shared lock and own lock)
              #
              node.unlock

              #
              # Tell the main thread that another node was computed.
              #
              condition.signal
            }
          }
          #trace "Thread #{thread_index} exiting"
        }
      }

      #trace "Main: waiting for threads to launch and block."
      until tree_mutex.synchronize { num_threads_ready == num_threads }
        Thread.pass
      end

      tree_mutex.synchronize {
        #trace "Main: entering main loop"
        until num_threads_ready == 0
          #trace "Main: waking threads"
          condition.broadcast

          if finished
            #trace "Main: detected finish."
            break
          end

          #trace "Main: waiting for a node"
          condition.wait(tree_mutex)
          #trace "Main: got a node"
        end
      }

      #trace "Main: waiting for threads to finish."
      threads.each { |t| t.join }

      #trace "Main: computation done."
      if finished.is_a? Exception
        raise finished
      else
        root.result
      end
    end
  end
end
