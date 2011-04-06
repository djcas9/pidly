require 'spec_helper'
require 'pidly'

describe Control do

  before do
    @daemon = Test.spawn(
      :name => 'YAY Daemon',
      :path => '/tmp',
      :verbose => false
    )

    @daemon.start
  end

  after do
    @daemon.kill
    # FileUtils.rm @daemon.log_path.to_s
    # FileUtils.rm @daemon.pid_path.to_s
  end

  it "should have successfully started both pidly daemons" do
    @daemon.messages.first.should == "blah"
  end

end
