module Pidly

  module Logger

    module LoggerMethods

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

    end # module LoggerMethods

    def self.included(receiver)
      receiver.extend         LoggerMethods
      receiver.send :include, LoggerMethods
    end

  end # class Logger

end # module Pidly
