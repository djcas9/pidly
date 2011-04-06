module Pidly

  module Logger

    attr_accessor :verbosity

    def verbose?
      @verbosity
    end

    def say(type, message)
      case type.to_sym
      when :info
        msg = message
      when :error
        msg = message
      end

      @messages << msg
      puts msg if verbose?
    end

    def self.included(receiver)
      receiver.extend self
    end

  end # class Logger

end # module Pidly
