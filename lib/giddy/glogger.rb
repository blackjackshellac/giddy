#!/usr/bin/env ruby

require 'logger'

class Logger
		def die(msg)
				self.error(msg)
				exit 1
		end
end

def set_logger(stream, level, rotate='daily')
		puts "c=#{stream.class}"
		case stream
		when IO
			$log = Logger.new(stream)
		when String
			$log = Logger.new(stream, rotate)
		else
			raise "invalid stream type #{stream.class}"
		end
		$log.level = level
		$log.datetime_format = "%Y-%m-%d %H:%M:%S"
		$log.formatter = proc do |severity, datetime, progname, msg|
				"#{severity} #{datetime}: #{msg}\n"
		end
end

