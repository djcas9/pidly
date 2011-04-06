module Pidly
  #
  # Pidly before/after callbacks
  # 
  module Callbacks

    def before_start(*callbacks)
      add_callback(:before_start, callbacks)
    end
    
    def start(*callbacks)
      add_callback(:start, callbacks)
    end
    
    def stop(*callbacks)
      add_callback(:stop, callbacks)
    end
    
    def after_stop(*callbacks)
      add_callback(:after_stop, callbacks)
    end
    
    def error(*callbacks)
      add_callback(:error, callbacks)
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