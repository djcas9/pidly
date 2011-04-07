require 'fileutils'
require 'pathname'

require 'pidly/callbacks'
require 'pidly/logger'

#
# Pidly namespace
#
module Pidly

  #
  # Pidly daemon control
  #
  class Control

    # Include callbacks
    include Pidly::Callbacks

    # Include logging helpers
    include Pidly::Logger

    attr_accessor :daemon, :name, :pid_file,
      :log_file, :path, :sync_log, :allow_multiple,
      :verbose, :pid, :timeout, :error_count, :messages

    #
    # Initialize control object
    #
    # @param [Hash] options The options to create a controller with.
    #
    # @option options [String] :name Daemon name
    #
    # @option options [String] :path Path to create the log/pids directory
    #
    # @option options [String] :pid_file Pid file path
    #
    # @option options [String] :log_file Log file path
    #
    # @option options [true, false] :sync_log Synchronize log files
    #
    # @option options [true, false] :allow_multiple
    #   Allow multiple daemons of the same type
    #
    # @option options [true, false] :sync_log Synchronize log files
    #
    # @option options [String] :signal Trap signal
    #
    # @option options [Integer] :timeout Timeout for Process#wait
    #
    # @option options [true, false] :verbose Display daemon messages
    #
    # @option options [true, false] :logger Enable daemon logging
    #
    # @return [Control] Control object
    #
    # @raise [RuntimeError]
    #   Raise exception if path does not exist
    #
    # @raise [RuntimeError]
    #   Raise exception if path is not readable or writable.
    #
    def initialize(options={})

      @messages = []

      @error_count = 0

      @name = options.fetch(:name)

      @path = if options.has_key?(:path)
        Pathname.new(options.fetch(:path))
      else
        Pathname.new('/tmp')
      end

      unless @path.directory?
        raise('Path does not exist or is not a directory.')
      end

      unless @path.readable? && @path.writable?
        raise('Path must be readable and writable.')
      end

      @pid_file = if options.has_key?(:pid_file)
        Pathname.new(options.fetch(:pid_file))
      else
        Pathname.new(File.join(@path.to_s, 'pids', @name + '.pid'))
      end

      @log_file = if options.has_key?(:log_file)
        Pathname.new(options.fetch(:log_file))
      else
        Pathname.new(File.join(@path.to_s, 'logs', @name + '.log'))
      end

      @pid = fetch_pid

      @sync_log = options.fetch(:sync_log, true)

      @allow_multiple = options.fetch(:allow_multiple, false)

      @signal = options.fetch(:signal, "TERM")

      @timeout = options.fetch(:timeout, 10)

      @verbosity = options.fetch(:verbose, true)

      @logger = options.fetch(:logger, true)

      validate_callbacks!

      validate_files_and_paths!
    end

    #
    # Spawn
    # 
    # @param [Hash] options Control object options
    #
    # @return [Control] Control object
    #
    # @see initialize
    # 
    # @example
    #   Test.spawn(
    #     :path => '/tmp',
    #     :verbose => true
    #   )
    # 
    def self.spawn(options={})
      @daemon = new(options)
    end

    #
    # Start
    #
    # Validate callbacks and start daemon
    #
    def start

      unless @allow_multiple
        if running?
          log(:error, "\"#{@name}\" is already running (PID: #{@pid})")
          return
        end
      end

      @pid = fork do
        begin
          Process.setsid

          open(@pid_file, 'w') do |f|
            f << Process.pid
            @pid = Process.pid
          end

          execute_callback(:before_start)

          Dir.chdir @path.to_s
          File.umask 0000

          if @logger
            log = File.new(@log_file, "a")
            log.sync = @sync_log

            STDIN.reopen "/dev/null"
            STDOUT.reopen log
            STDERR.reopen STDOUT
          end

          trap("TERM") do
            stop
          end

          execute_callback(:start)

        rescue RuntimeError => message
          STDERR.puts message
          STDERR.puts message.backtrace

          execute_callback(:error)
        rescue => message
          STDERR.puts message
          STDERR.puts message.backtrace

          execute_callback(:error)
        end
      end

    rescue => message
      STDERR.puts message
      STDERR.puts message.backtrace
      execute_callback(:error)
    end

    #
    # Stop
    #
    # Stop daemon and remove pid file
    #
    def stop

      if running?

        Process.kill(@signal, @pid)
        FileUtils.rm(@pid_file)

        execute_callback(:stop)

        begin
          Process.wait(@pid)
        rescue Errno::ECHILD
        end

        @timeout.downto(0) do
          sleep 1
          exit unless running?
        end

        Process.kill 9, @pid if running?
        execute_callback(:after_stop)

      else
        FileUtils.rm(@pid_file) if File.exists?(@pid_file)
        log(:info, "\"#{@name}\" PID file not found.")
      end

    rescue Errno::ENOENT
    end

    #
    # Status
    #
    # Return current daemon status and pid
    #
    # @return [String] Status
    #
    def status
      if running?
        log(:info, "\"#{@name}\" is running (PID: #{@pid})")
      else
        log(:info, "\"#{@name}\" is NOT running")
      end
    end

    #
    # Restart
    #
    # Restart the daemon
    #
    def restart
      stop; sleep 1 while running?; start
    end

    #
    # Kill
    #
    # @param [String] remove_pid_file Remove the daemon pid file
    #
    def kill(remove_pid_file=true)
      if running?
        log(:info, "Killing \"#{@name}\" (PID: #{@pid})")
        execute_callback(:kill)
        Process.kill 9, @pid
      end

      FileUtils.rm(@pid_file) if remove_pid_file
    rescue Errno::ENOENT
    end

    #
    # Running?
    #
    # @return [true, false] Return the running status of the daemon.
    #
    def running?
      Process.kill 0, @pid
      true
    rescue Errno::ESRCH
      false
    rescue Errno::EPERM
      true
    rescue
      false
    end

    #
    # Clean
    #
    # Remove all files created by the daemon.
    #
    def clean!
      FileUtils.rm(@log_file)
      FileUtils.rm(@pid_file)
    rescue Errno::ENOENT
    end

    #
    # Fetch Class Variable
    #
    # @param [Symbol] name Callback name
    #
    # @return [Symbol, Proc, nil]
    #   Returns either a method or block of code to be executed when
    #   the callback is called. If no value is accossiated with the
    #   call variable `nil` will be returned to the caller.
    #
    def fetch_class_var(name)
      Control.instance_eval do
        return nil unless class_variable_defined?(:"@@#{name}")

        class_variable_get(:"@@#{name}")
      end
    end

    def validate_files_and_paths!
      unless @log_file.directory?
        FileUtils.mkdir_p(@log_file.dirname)
      end

      unless @pid_file.directory?
        FileUtils.mkdir_p(@pid_file.dirname)
      end
    end

    def validate_callbacks!
      parent = self
      Control.instance_eval do

        unless class_variable_defined?(:"@@start")
          raise('You must define a "start" callback.')
        end

        class_variables.each do |cvar|
          value = class_variable_get(:"#{cvar}")

          next unless value.is_a?(Symbol)
          next if parent.respond_to?(value)

          raise("Undefined callback method: #{value}")
        end
      end
    end

    def execute_callback(callback_name)
      @error_count += 1 if callback_name == :error

      if (callback = fetch_class_var(callback_name))

        if callback.kind_of?(Symbol)
          self.send(callback.to_sym)
        elsif callback.respond_to?(:call)
          self.instance_eval(&callback)
        else
          nil
        end

      end
    end

    def fetch_pid
      IO.read(@pid_file).to_i
    rescue
      nil
    end

    private :validate_callbacks!, :fetch_pid,
      :validate_files_and_paths!, :execute_callback

  end # class Control

end # module Pidly
