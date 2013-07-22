#!/usr/bin/env ruby

require 'logger'

class Logger
		def die(msg)
				self.error(msg)
				exit 1
		end
end

def set_logger(stream, level=Logger::INFO)
		$log = Logger.new(stream)
		$log.level = level
		$log.datetime_format = "%Y-%m-%d %H:%M:%S"
		$log.formatter = proc do |severity, datetime, progname, msg|
				"#{severity} #{datetime}: #{msg}\n"
		end
end

