#!/usr/bin/env ruby

require 'logger'
require 'fileutils'

class Logger
		def die(msg)
				self.error(msg)
				exit 1
		end
end

def set_logger(file, level, opts={:rotate=>'daily', :log_dir=>"/var/tmp/giddy/log"})
		case file
		when IO
			$log = Logger.new(file)
		when String
			puts "opts="+opts.inspect
			FileUtils.mkdir_p opts[:log_dir]
			$log = Logger.new(opts[:log_dir]+"/"+file, opts[:rotate])
		else
			raise "invalid logger file type #{file.class}"
		end
		$log.level = level
		$log.datetime_format = "%Y-%m-%d %H:%M:%S"
		$log.formatter = proc do |severity, datetime, progname, msg|
				"#{severity} #{datetime}: #{msg}\n"
		end
		$log
end
