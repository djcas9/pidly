require 'spec_helper'
require 'pidly'

describe Control do

  before(:all) do
    @daemon = Test.spawn(
      :name => 'YAY Daemon',
      :path => '/tmp',
      :verbose => true
    )
    @daemon.kill if @daemon.running?
    @daemon.start
    sleep 1
  end

  it "should have successfully started both pidly daemons" do
    @daemon.status
    reply = "#{@daemon.name} is running (PID #{@daemon.pid})"
    @daemon.messages.last.should == reply
  end
  
  
  
  after(:all) do
    @daemon.kill if @daemon
    # FileUtils.rm @daemon.log_path.to_s
    # FileUtils.rm @daemon.pid_path.to_s
  end

end
