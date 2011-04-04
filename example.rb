$:.unshift File.join(File.dirname(__FILE__), "lib")

require 'pidly'
require 'pp'

class Test < Pidly::Control
  
  include DaemonCommands
  
  before_start :test_pidly_on_start
  
  start :start!
  
  stop :clean!
  
  error :send_email
  
  after_stop :test_pidly_on_stop
  
  
  def start!

    20.times do |i|
      
      puts "#{i}: #{Time.now} hello!"
      
      sleep 1
      
      if i == 4
        raise('ERROR w0ots w0ots')
      end
      
      exit if i == 15
    end
    
  end
  
  def clean!
    puts "#{@pid} done!"
  end
  
  def test_pidly_on_start
    puts "BEFORE START #{@pid}"
  end
  
  def test_pidly_on_stop
    puts "AFTER STOP #{@pid}"
  end
  
  def send_email
    puts "SENDING EMAIL | Error Count: #{@error_count}"
  end
  
end

@daemon = Test.spawn(
  :name => 'Test Daemon',
  :path => '/tmp',
  :verbose => false
)

@daemon.send ARGV.first

