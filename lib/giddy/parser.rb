#!/usr/bin/env ruby
# 
#

require 'optparse'

#module GiddyUtils
	def parse(args)
		@options={
			:include=>[],
			:exclude=>[],
			:debug=>false,
			:dryrun=>false
		}
		opts = OptionParser.new
		opts.on('-h', '--help', "Print help") { puts opts.to_s; exit 0 }
		opts.on('-v', '--version', "Version") { puts "too early to tell" }

		# boolean options
		opts.on('-d', '--debug', "Debug") { @options[:debug]=true }
		opts.on('-n', '--dry-run', "Just a run through, don't perform backup") { @options[:dryrun]=true }

		opts.on('-i', '--include INC', Array, "Files/directories to be included") { |inc|
			puts "Including #{inc}"
			@options[:include]+=inc
		}
		opts.on('-x', '--exclude EXC', Array, "Files/directories to be excluded") { |exc|
			puts "Excluding #{exc}"
			@options[:exclude]+=exc
		}
		opts.parse!(args)
		@options
	end
#end

