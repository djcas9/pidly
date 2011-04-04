module Pidly
  #
  # Pidly before/after callbacks
  # 
  module Callbacks

    #
    # All available callback methods
    # 
    AVAILABLE_CALLBACKS = [
      :before_start,
      :start,
      :stop,
      :after_stop,
      :error
    ]

    #
    # Extend and include callback methods
    # 
    def self.included(receiver)
      receiver.extend         CallbackMethods
      receiver.send :include, CallbackMethods
    end

    #
    # Callback methods
    # 
    module CallbackMethods
      
      #
      # Define callbacks
      # 
      # Define callbacks and create
      # class varabiles holding method calls
      # for the given callback location
      # 
      def self.define_callbacks
        Callbacks::AVAILABLE_CALLBACKS.each do |method_name|  
          instance_eval do
            
            define_method method_name do |*call_methods|
              Control.class_variable_set(:"@@#{method_name}", [])

              call_methods.each do |method|
                next unless method
                Control.class_variable_get(:"@@#{method_name}") << method
              end
            end

          end
        end
      end

      # 
      # Define callbacks
      # 
      define_callbacks
      
    end # module CallbackMethods

  end # modle Callbacks
  
end # module Pidly
