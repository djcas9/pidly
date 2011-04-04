module Pidly

  module Logger

    module LoggerMethods

      def verbosity(verbosity=true)
        verbosity
      end

      def verbose?
        verbosity
      end

      def say(type, message)
        case type.to_sym
        when :info
          puts message if verbose?
        when :error
          puts message
        end
      end

    end # module LoggerMethods

    def self.included(receiver)
      receiver.extend         LoggerMethods
      receiver.send :include, LoggerMethods
    end

  end # class Logger

end # module Pidly
