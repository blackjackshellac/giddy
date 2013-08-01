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

	def GiddyUtils.usage
		usage=%q{

-i|--include INC_LIST
-x|--exclude EXC_LIST

   A semi-colon delimited list of files or directories.  Directory
   names are specified with a path slash ending the entry.  The entries
   are case sensitive, so cache and Cache must be set explicitly.

   For example,

   '*.txt;.git/;*.log;*.gz;cache/' will include or exclude the
   files with extension txt, log and gz and the directories .git
   and cache.

   The include and exclude options can be specified multiple times.

--ire /INC_REGEX/i?
--xre /EXC_REGEX/i?

   Regular expressions for inclusion and exclusion.  Append 'i'
   for a case insensitive match.

   For example, to exclude directories named cache or Cache you
   could use either of the following,

   --xre '[cC]ache[/]'
   --xre '/cache\//i'

		}

		puts usage
	end

	def GiddyUtils.set_regex(str, key)
		begin
			opts=0
			re=/\/(.*)\/(i)?/
			unless str[re].nil?
				str=$1
				opts=Regexp::IGNORECASE if "i".eql?($2)
			end
			$log.debug "str=#{str} opts=#{opts}"
			Regexp.new(str, opts)
		rescue => e
			$log.die("Invalid --#{key.to_s} regular expression '#{str}': #{e.message}")
		end

	end

	def GiddyUtils.lookup_backup(pos)
		case pos
		when :first
			# TODO
			"first backup name"
		when :last
			# TODO
			"last backup name"
		else
			$log.die "unknown backup position #{pos.to_s}"
		end
	end

	def GiddyUtils.parse(args)
		@options={
			:include=>[],
			:exclude=>[],
			:ire=>[],
			:xre=>[],
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
				puts opts.to_s;
				exit 0
			}

			opts.on('-U', '--usage', "Print usage examples") {
				GiddyUtils.usage
				exit 0
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

			opts.on('-i', '--include INC', String, "Files/directories to be included") { |inc|
				@options[:include] += inc.split(/;/)
				@options[:include].flatten!.uniq!
			}

			opts.on('-x', '--exclude EXC', String, "Files/directories to be excluded") { |exc|
				@options[:exclude] += exc.split(/;/)
				@options[:exclude].flatten!.uniq!
			}

			opts.on('--ire REGEX', String, "") { |ire|
				@options[:ire] << GiddyUtils.set_regex(ire, :ire)
			}

			opts.on('--xre REGEX', String, "Exclude regular expression") { |xre|
				@options[:xre] << GiddyUtils.set_regex(xre, :xre)
			}

			opts.on('-l', '--list', "List available backups") {
				@options[:action]=:LIST
			}

			opts.on('-b', '--backup [NAME]', String, "Create new backup (default #{Time.now.strftime("%Y%m%d")})") { |name|
				@options[:action]=:BACKUP
				@options[:backup]=name || Time.now.strftime("%Y%m%d")
			}

			opts.on('-u', '--update [NAME]', String, "Update the most recent or named backup") { |name|
				@options[:action]=:UPDATE
				@options[:backup]=name || lookup_backup(:last)
			}

			opts.on('--verify', "Verify content directory data") {
				# read content and verify sha256 for each content file
				@options[:action]=:VERIFY
			}

			opts.on('-d', '--delete [NAME]', String, "Delete the oldest or the named backup") { |name|
				@options[:action]=:DELETE
				@options[:backup]=name || lookup_backup(:first)
			}
		}
		op.parse!(args)
		puts @options.inspect
		exit 1
		@options
	end
end

