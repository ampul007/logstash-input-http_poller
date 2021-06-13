    # Class to perform async splitting of the API response
    
    require 'concurrent'
    
    class AsyncSplitter
        include Concurrent::Async
        
        def splitter(list_name,event,queue,logger)
            
            logger.debug("Splitting started by the thread: ", :thread_name => Thread.current.object_id)
            # Check if the list item is present in the response
            # If present, split the event into multiple row events
            # If not present, process the event as it is
            if event.get(list_name) && !event.get(list_name).empty?
                data = event.remove(list_name)
                logger.debug("Remaining event: ", :event => event.to_s)
                event.cancel
                data.each_with_index { |item,index|
                    logger.debug("Split event index: ", :index => index)
                    split_event = LogStash::Event.new
                    split_event.set(list_name, item)
                    queue << split_event
                }
            else
                queue << event
            end
        end
        
    end
    