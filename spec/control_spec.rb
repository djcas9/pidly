require 'spec_helper'
require 'pidly'

describe Control do

  before(:all) do
    @daemon = Test.spawn(
      :name => 'test',
      :path => '/tmp',
      :verbose => false
    )
    @daemon.kill if @daemon.running?
    @daemon.start
    sleep 1
  end

  it "should be running" do
    @daemon.running?.should == true
  end

  it "should have an active status, name and pid" do
    @daemon.status
    reply = "\"#{@daemon.name}\" is running (PID: #{@daemon.pid})"
    
    @daemon.messages.last.should == reply
  end

  it "should have the correct pid path" do
    @daemon.pid_file.to_s.should == "/tmp/pids/#{@daemon.name}.pid"
  end

  it "should have a pid file that exists" do
    File.exists?("/tmp/pids/#{@daemon.name}.pid").should == true
  end

  it "should have the correct log file" do
    @daemon.log_file.to_s.should == "/tmp/logs/#{@daemon.name}.log"
  end

  it "should have a log file that exists" do
    File.exists?("/tmp/logs/#{@daemon.name}.log").should == true
  end

  it "should fail when trying to start another daemon" do
    @daemon.start
    reply = "\"#{@daemon.name}\" is already running (PID: #{@daemon.pid})"

    @daemon.messages.last.should == reply
  end

  it "should write to the log file" do
    file = File.open(@daemon.log_file, 'r')
    file.read.should =~ /TEST FROM #{@daemon.pid}/
  end

  it "should write to the pid file" do
    file = File.open(@daemon.pid_file, 'r')
    file.read.should =~ /#{@daemon.pid}/
  end
  
  it "should not have a start callback defined" do
    test_callback(:start, true).should == true
  end
  
  it "should not have a stop callback defined" do
    test_callback(:stop).should == "Attempting to kill process: "
  end
  
  it "should not have a before_start callback defined" do
    test_callback(:before_start).should == "BEFORE START "
  end
  
  it "should not have a after_stop callback defined" do
    test_callback(:after_stop).should == :test_after_daemon_stops
  end
  
  it "should have an error callback defined" do
    test_callback(:error).should == "SENDING EMAIL | Error Count: "
  end
  
  it "should not have a kill callback defined" do
    test_callback(:kill).should == nil
  end

  after(:all) do
    if @daemon
      @daemon.kill
      @daemon.clean!
    end
  end

end
