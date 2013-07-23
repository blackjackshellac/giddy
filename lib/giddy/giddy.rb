#!/usr/bin/env ruby

require 'find'
require 'fileutils'
require 'digest/sha2'
require 'json'
require 'benchmark'

rreqdir=File.expand_path(File.dirname(__FILE__))
$:.unshift(rreqdir) unless $:.include?(rreqdir)

require 'parser'
require 'gfile'
require 'gentry'
require 'glogger'

class Main
	attr_reader :args, :content_dir, :excludes

	GIDDYDATA="/giddydata.json"

	def initialize(args)
		@backup_dir="/home/backup/giddy"
		@content_dir="#{@backup_dir}/.content"
		@stats={
			:start_time=>Time.now,
			:end_time=>nil,
			:bytes=>0,
			:bps=>0,
			:file=>0,
			:dir=>0
		}
		@options=parse_args(args)
	end

	def parse_args(args)
		@options=parse(args)

		@excludes = {
			:file=>[],
			:dir=>[]
		}
		@options[:exclude].each { |exc|
			$log.debug "exc=#{exc.inspect}"
			exc.strip!
			key=:file
			unless exc[/\/$/].nil?
				key=:dir
				#exc.chop!
			end
			@excludes[key] << exc.chop!
		}
		[:file, :dir].each { |key|
			if @excludes[key].empty?
				@excludes[key]=nil
			else
				@excludes[key]="("+@excludes[key].join("|")+")"
				$log.debug "excludes[#{key}]="+@excludes[key]
				@excludes[key]=/#{@excludes[key]}/
			end
		}
		@options
	end

#	{
#		"." => ge,
#		".." => ge".",
#		"file" => ge"file",
#		"dir" => {
#			"." => ge(.),
#			".." => ge(..),
#			"foo"=> ge(foo)
#			...
#		}
#	}

	def is_excluded(dir, key)
		re=@excludes[key]
		if re.nil? || dir[re].nil?
			false
		else
			$log.debug "Excluding #{key.to_s}=#{dir}"
			true
		end
	end

	def write_dh(cur_dir, dir_hash)

		backup_dir=@backup_dir+cur_dir
		FileUtils.mkdir_p(backup_dir)
		ofile=backup_dir+GIDDYDATA

		json=JSON.pretty_generate(dir_hash, :max_nesting=>false)

		File.open(ofile, "w+") { |fd|
			fd.write json
			puts json
		}

	end

	def read_dh(cur_dir)
		backup_dir=@backup_dir+cur_dir
		FileUtils.mkdir_p(backup_dir)
		ifile=backup_dir+GIDDYDATA
		dir_hash={}
		if File.exists?(ifile)
			json=File.read(ifile)
			dir_hash=JSON.parse(json)
		end
		dir_hash
	end

	def gfind(cur_dir)
		fre=@excludes[:file]
		begin
			FileUtils.chdir(cur_dir) {
				cur_dir=FileUtils.pwd
				dir_hash={}
				old_hash=read_dh(cur_dir)
				$log.debug "Changed to #{cur_dir}: old_hash=#{dir_hash.inspect}"
				puts old_hash.inspect
				names=[]
				entries=Dir.glob("{*,.*}")
				entries.each { |dir_entry|
					next if dir_entry.eql?("..")

					ge=Gentry.new(dir_entry)
					if ge.stat.dir?
						next if is_excluded(dir_entry, :dir)
						@stats[:dir]+=1
						gfind(dir_entry) unless dir_entry.eql?('.')
					elsif ge.stat.file?
						next if is_excluded(dir_entry, :file)
						@stats[:file]+=1
						@stats[:bytes]+=ge.stat.size
						if old_hash.has_key?(dir_entry)
							oge=Gentry.from_hash(old_hash[dir_entry])
							puts "oge="+oge.to_json
							if ge.eql?(oge)
								$log.debug "found #{dir_entry} in old_hash: the same as new entry"
							else
								$log.debug "found #{dir_entry} in old_hash: not the same as new entry"
							end
						end
						ge.save_content(@content_dir)
						#dir_hash[dir_entry]=ge
					else
						#dir_hash[dir_entry]=ge
					end
					$log.debug "  dir_entry=#{cur_dir}/#{dir_entry}"
					dir_hash[dir_entry]=ge
					names<<dir_entry
				}
				# get each dir_entry in this sorted directory list
				snames=names.sort.join(",")
				$log.debug "entries=#{cur_dir}:#{snames}"
				dir_hash["."].sha2=(Digest::SHA2.new << snames).to_s

				write_dh cur_dir, dir_hash
			}
		rescue => e
			$log.debug "e="+e.message
			$log.debug e.backtrace.join("\n")
			$log.debug ":"+cur_dir.class.to_s
			if cur_dir[/^\//]
				$log.error "Failed to change to #{cur_dir}"
			else
				$log.error "Failed to change to #{FileUtils.pwd}/#{cur_dir}"
			end
			return
		end

	end

	def run
		@stats[:start_time]=Time.now.to_f

		@options[:include].each { |inc|
			begin
				FileUtils.chdir(inc) {
					gfind(FileUtils.pwd)
				}
			rescue
				$log.error "Error: failed to change to include #{inc}"
				next
			end
		}

		@stats[:end_time]=Time.now.to_f

		@stats[:elapsed_time]=@stats[:end_time]-@stats[:start_time]

		# fast JSON streaming (yet another json library)
		# https://github.com/brianmario/yajl-ruby

		puts JSON.pretty_generate(@stats)

	end
end

set_logger(STDOUT, Logger::DEBUG)

giddy=Main.new(ARGV)
giddy.run

