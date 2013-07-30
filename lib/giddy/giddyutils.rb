#!/usr/bin/env ruby
#
#

require 'optparse'
require 'glogger'

module GiddyUtils
	def GiddyUtils.daemonize_app
		if RUBY_VERSION < "1.9"
			exit if fork
			Process.setsid
			exit if fork
			Dir.chdir "/"
			STDIN.reopen "/dev/null"
			STDOUT.reopen "/dev/null", "a"
			STDERR.reopen "/dev/null", "a"
		else
			Process.daemon
		end
	end

	def GiddyUtils.parse(args)
		@options={
			:include=>[],
			:exclude=>[],
			:debug=>false,
			:dryrun=>false,
			:action=>:LIST,
			:log_rotate=>'daily',
			:log_level=>Logger::INFO,
			:log_stream=>STDERR,
			:backup=>Time.now.strftime("%Y%m%d"),
			:daemonize=>false
		}
		op = OptionParser.new { |opts|
			opts.on('-h', '--help', "Print help") {
				puts opts.to_s; exit 0
			}
			opts.on('--init', "Initialize giddy") {
				@options[:action]=:INIT
			}
			opts.on('-v', '--version', "Version") {
				puts "too early to tell"
			}
			opts.on('-D', '--debug', "Debug") {
				@options[:debug]=true
				@options[:log_level]=Logger::DEBUG
			}
			opts.on('-B', '--background', "Daemonize the script") {
				@options[:daemonize]=true
				@options[:log_stream]="giddy.log"
			}

			opts.on('-L', '--log FILE', "Log file") { |file|
				if file.eql?("stdout")
					@options[:log_stream]=STDOUT
				elsif file.eql?("stderr")
					@options[:log_stream]=STDERR
				else
					@options[:log_stream]=file
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
			opts.on('-b', '--backup [NAME]', String, "Create new backup (default #{Time.now.strftime("%Y%m%d")})") { |name|
				@options[:action]=:BACKUP
				@options[:backup]=name || Time.now.strftime("%Y%m%d")
			}
			opts.on('--verify', String, "Verify content directory data") {
				@options[:action]=:VERIFY
			}

			opts.on('-u', '--update', "") {
				@options[:action]=:UPDATE
			}
			opts.on('-d', '--delete', "") {
				@options[:action]=:DELETE
			}
		}
		op.parse!(args)
		@options
	end
end

