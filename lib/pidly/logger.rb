module Pidly
  #
  # Logger namespace
  # 
  module Logger

    attr_accessor :verbosity
    
    #
    # Verbose
    # 
    # @return [true, false] Is the logging level verbose?
    # 
    def verbose?
      @verbosity
    end
    
    #
    # Log
    # 
    # @param [String, Symbol] type Log type (info or error)
    # @param [String] message Log message
    # 
    # @return [Strign] Log message
    # 
    def log(type, message)
      case type.to_sym
      when :info
        msg = message
      when :error
        msg = message
      end

      @messages << msg
      puts msg if verbose?
    end
    
    #
    # Extend and include callback methods
    # 
    # @param [Class] receiver The calling class
    #
    def self.included(receiver)
      receiver.extend self
    end

  end # class Logger

end # module Pidly