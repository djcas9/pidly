# pidly

* [Homepage](https://github.com/mephux/pidly)
* [Documentation](http://rubydoc.info/github/mephux/pidly/master/frames)

## Description

Pidly is a very minimalistic daemon library that doesn't make assumptions. Pidly allows you to control the 
daemon without getting in the way with forced verbose output and usage messages.

## Examples

	require 'pidly'

	class Test < Pidly::Control

	  before_start do
	    "BEFORE START #{@pid}"
	  end

	  start :when_daemon_starts

	  stop do
	    "Attempting to kill process: #{@pid}"
	  end

	  after_stop :test_after_daemon_stops

	  error do
	    "SENDING EMAIL | Error Count: #{@error_count}"
	  end

	  def when_daemon_starts
	    loop do
	      print "TEST FROM #{@pid}"
	      sleep 2
	    end
	  end

	end

	@daemon = Test.spawn(
	  :name => 'Test Daemon',
	  :path => '/tmp',
	  :verbose => true
	)

	# @daemon.send ARGV.first
	@daemon.start # stop, status, restart, and kill.

## Install

	$ gem install pidly

## Copyright

Copyright (c) 2011 Dustin Willis Webber

See LICENSE.txt for details.
