#!/usr/bin/env ruby
# 
#

require 'optparse'

module Giddy
	class Parser
		def parse(args)
			opts = OptionParser.new
			opts.on('-h', '--help', "Print help") { puts "Help!" }
			opts.on('-v', '--version', "Version") { puts "too early to tell" }
			opts.on('-d', '--debug', "Debug") { puts "debug me" }
			opts.on('-i', '--include INC', String, "Files/directories to be included") { |inc|
				puts "Including #{inc}"
			}
			opts.on('-x', '--exclude EXC', String, "Files/directories to be excluded") { |exc|
				puts "Excluding #{exc}"
			}
			opts.parse!(args)
		end
	end
end

