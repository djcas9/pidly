module Pidly
  #
  # Pidly before/after callbacks
  # 
  module Callbacks
    
    #
    # Before start
    # 
    # Right before the daemon is instructed to start the 
    # following callback will be invoked and executed.
    # 
    # @param [Symbol] callback Method name
    # @yield [] Code to be executed upon callback invocation
    #
    # @example 
    #   before_start :method_name
    #   # OR
    #   before_start { puts "#{@pid} is about to start!" }
    #
    def before_start(callback=nil, &block)
      add_callback(:before_start, (callback || block))
    end
    
    #
    # Start
    # 
    # When the daemon is instructed to start the 
    # following callback will be invoked and executed.
    # 
    # @param [Symbol] callback Method name
    # @yield [] Code to be executed upon callback invocation
    #
    # @example 
    #   start :method_name
    #   # OR
    #   start { puts "Daemon Started!" }
    # 
    def start(callback=nil, &block)
      add_callback(:start, (callback || block))
    end
    
    #
    # Stop
    # 
    # When the daemon is instructed to stop the 
    # following callback will be invoked and executed.
    # 
    # @param [Symbol] callback Method name
    # @yield [] Code to be executed upon callback invocation
    # 
    # @example 
    #   stop :method_name
    #   # OR
    #   stop { puts "Attempting to stop #{@name} with pid #{@pid}!" }
    # 
    def stop(callback=nil, &block)
      add_callback(:stop, (callback || block))
    end
    
    #
    # After stop
    # 
    # Right after the daemon is instructed to stop the 
    # following callback will be invoked and executed.
    # 
    # @param [Symbol] callback Method name
    # @yield [] Code to be executed upon callback invocation
    #
    # @example 
    #   after_start :method_name
    #   # OR
    #   after_start { puts "#{@pid} was just killed!" }
    #
    def after_stop(callback=nil, &block)
      add_callback(:after_stop, (callback || block))
    end
    
    #
    # Error
    # 
    # If the daemon encounters an error or an exception is raised
    # the following callback will be invoked and executed.
    # 
    # @param [Symbol] callback Method name
    # @yield [] Code to be executed upon callback invocation
    #
    # @example 
    #   error :send_error_email
    #   # OR
    #   error { puts "ZOMG! #{@name} failed!" }
    #
    def error(callback=nil, &block)
      add_callback(:error, (callback || block))
    end

    #
    # Add callback
    # 
    # @param [Symbol] callback Callback method name
    # @param [Symbol, nil] invoke Method to call
    # @yield [] Code to be executed upon callback invocation
    # 
    def add_callback(callback, invoke)
      Control.class_variable_set(:"@@#{callback}", invoke)
    end

    #
    # Extend and include callback methods
    # 
    # @param [Class] receiver The calling class
    # 
    def self.included(receiver)
      puts receiver.class
      receiver.extend self
    end

  end # modle Callbacks
  
end # module Pidly