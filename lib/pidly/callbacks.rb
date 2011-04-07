module Pidly
  #
  # Pidly before/after callbacks
  # 
  module Callbacks

    def before_start(callback=nil, &block)
      add_callback(:before_start, (callback || block))
    end
    
    def start(callback=nil, &block)
      add_callback(:start, (callback || block))
    end
    
    def stop(callback=nil, &block)
      add_callback(:stop, (callback || block))
    end
    
    def after_stop(callback=nil, &block)
      add_callback(:after_stop, (callback || block))
    end
    
    def error(callback=nil, &block)
      add_callback(:error, (callback || block))
    end

    def add_callback(callback, methods)
      Control.class_variable_set(:"@@#{callback}", methods)
    end

    #
    # Extend and include callback methods
    # 
    def self.included(receiver)
      receiver.extend self
    end

  end # modle Callbacks
  
end # module Pidly