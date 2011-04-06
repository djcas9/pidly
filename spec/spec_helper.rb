gem 'rspec', '~> 2.4'
require 'rspec'

require 'pidly'
include Pidly

class Test < Pidly::Control

  before_start :test_before_daemon_starts

  start :when_daemon_starts

  stop :when_daemon_stops

  after_stop :test_after_daemon_stops
  
  error :on_daemon_error_send_email

  def test_before_daemon_starts
    puts "BEFORE START #{@pid}"
  end

  def when_daemon_starts
    loop do
      puts Time.now
      sleep 2
    end
  end

  def when_daemon_stops
    puts "Attempting to kill process: #{@pid}"
  end

  def test_after_daemon_stops
    puts "AFTER STOP #{@pid}"
  end

  def send_email
    puts "SENDING EMAIL | Error Count: #{@error_count}"
  end

end

@daemon = Test.spawn(
  :name => 'Test Daemon',
  :path => '/tmp',
  :verbose => true
)

# @daemon.send ARGV.first
@daemon.start # stop, status, restart, and kill.