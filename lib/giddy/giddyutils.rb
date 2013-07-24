#!/usr/bin/env ruby
# 
#

require 'optparse'
require 'glogger'

module GiddyUtils

	def GiddyUtils.parse(args)
		@options={
			:include=>[],
			:exclude=>[],
			:debug=>false,
			:dryrun=>false,
			:action=>:LIST,
			:log_rotate=>'daily',
			:log_level=>Logger::INFO,
			:log_stream=>STDERR
		}
		parser = OptionParser.new { |opts|
			opts.on('-h', '--help', "Print help") {
				puts opts.to_s; exit 0
			}
			opts.on('-v', '--version', "Version") {
				puts "too early to tell"
			}

			# boolean options
			opts.on('-d', '--debug', "Debug") {
				@options[:debug]=true
				@options[:log_level]=Logger::DEBUG
			}

			opts.on('-L', '--log DIR', "Log directory") { |dir|
				if dir.eql?("stdout")
					@options[:log_stream]=STDOUT
				elsif dir.eql?("stderr")
					@options[:log_stream]=STDERR
				else
					@options[:log_stream]=dir
				end
			}

			opts.on('-n', '--dry-run', "Just a run through, don't perform backup") {
				@options[:dryrun]=true
			}
			opts.on('-i', '--include INC', Array, "Files/directories to be included") { |inc|
				@options[:include] += inc
			}
			opts.on('-x', '--exclude EXC', Array, "Files/directories to be excluded") { |exc|
				@options[:exclude] += exc
			}

			opts.on('-l', '--list', "List available backups") {
				@options[:action]=:LIST
			}
			opts.on('-b', '--backup [NAME]', String, "Create new backup") {
				@options[:action]=:BACKUP
			}
			opts.on('-u', '--update', "") {
				@options[:action]=:UPDATE
			}
			opts.on('-d', '--delete', "") {
				@options[:action]=:DELETE
			}
		}
		parser.parse!(args)
		@options
	end
end

