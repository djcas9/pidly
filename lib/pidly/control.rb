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

      if options.has_key?(:path)
        @path = Pathname.new(options.fetch(:path))
      else
        @path = Pathname.new('/tmp')
      end

      unless @path.directory?
        raise('Path does not exist or is not a directory.')
      end

      unless @path.readable? && @path.writable?
        raise('Path must be readable and writable.')
      end

      if options.has_key?(:pid_file)
        @pid_file = options.fetch(:pid_path)
      else
        @pid_file = File.join(@path.to_s, 'pids', @name + '.pid')
      end

      if options.has_key?(:log_file)
        @log_file = options.fetch(:log_path)
      else
        @log_file = File.join(@path.to_s, 'logs', @name + '.log')
      end

      @pid = fetch_pid if File.file?(@pid_file)

      @sync_log = options.fetch(:sync_log, true)

      @allow_multiple = options.fetch(:allow_multiple, false)

      @signal = options.fetch(:signal, "TERM")

      @timeout = options.fetch(:timeout, 10)

      @verbosity = options.fetch(:verbose, false)

      @logger = options.fetch(:logger, true)
    end

    #
    # Spawn
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
    def self.spawn(options={})
      @daemon = new(options)
    end

    #
    # Start
    #
    # Validate callbacks and start daemon
    #
    def start
      validate_files_and_paths!
      validate_callbacks!

      unless @allow_multiple
        if running?
          log(:error, "#{@name} is already running (PID #{@pid})")
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
        log(:info, "PID file not found.")
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
        log(:info, "#{@name} is running (PID #{@pid})")
      else
        log(:info, "#{@name} is NOT running")
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
        log(:info, "Killing #{@name} (PID #{@pid})")
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

    def validate_files_and_paths!
      log = Pathname.new(@log_file).dirname
      pid = Pathname.new(@pid_file).dirname

      unless File.directory?(log)
        FileUtils.mkdir_p(log.to_s)
      end

      unless File.directory?(pid)
        FileUtils.mkdir_p(pid.to_s)
      end
    end

    def validate_callbacks!
      unless Control.class_variable_defined?(:"@@start")
        raise('You must define a "start" callback.')
      end
    end

    def execute_callback(callback_name)
      @error_count += 1 if callback_name == :error

      if (callback = fetch_class_var(callback_name))

        if callback.kind_of?(Symbol)

          unless self.respond_to?(callback.to_sym)
            raise("Undefined callback method: #{callback}")
          end

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

    def fetch_class_var(name)
      if Control.class_variable_defined?(:"@@#{name}")
        Control.instance_eval do
          return class_variable_get(:"@@#{name}")
        end
      end
    end

    private :validate_callbacks!, :fetch_pid,
      :validate_files_and_paths!, :execute_callback,
      :fetch_class_var

  end # class Control

end # module Pidly
