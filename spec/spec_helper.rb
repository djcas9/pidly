gem 'rspec', '~> 2.4'
require 'rspec'

require 'pp'
require 'pidly'
include Pidly

class Test < Pidly::Control

  before_start :test_before_daemon_starts

  start :when_daemon_starts

  stop :when_daemon_stops

  after_stop :test_after_daemon_stops
  
  error :on_daemon_error_send_email

  def test_before_daemon_starts
    "BEFORE START #{@pid}"
  end

  def when_daemon_starts
    loop do
      puts "TEST FROM #{@pid}"
      sleep 2
    end
  end

  def when_daemon_stops
    "Attempting to kill process: #{@pid}"
  end

  def test_after_daemon_stops
    "AFTER STOP #{@pid}"
  end

  def send_email
    "SENDING EMAIL | Error Count: #{@error_count}"
  end

end