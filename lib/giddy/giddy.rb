#!/usr/bin/env ruby

require 'find'
require 'fileutils'
require 'digest/sha2'
require 'json'
require 'benchmark'
require 'zlib'

rreqdir=File.expand_path(File.dirname(__FILE__))
$:.unshift(rreqdir) unless $:.include?(rreqdir)

require 'giddyconfig'
require 'giddyutils'
require 'gentry'
require 'glogger'

class Giddy
	attr_reader :args, :content_dir, :excludes, :config, :options

	GIDDYDATA="/giddydata.json"

	def initialize(args)
		@config=GiddyConfig.new

		@content_dir=@config.content_dir
		@backups=@config.backups
		@stats=@config.stats
		@log_dir=@config.log_dir

		@options=parse_args(args)

		@backup_dir=@config.backup_dir + "/" + @options[:backup]
		@zmeta=@config.compress[:metadata]
		@zcont=@config.compress[:content]
	end

	def parse_args(args)
		@options=GiddyUtils.parse(args)

		$log.debug @options.inspect

		set_logger(@options[:log_stream], @options[:log_level], :rotate=>@options[:log_rotate], :log_dir=>@log_dir)

		$log.debug "Including #{@options[:include].inspect}"
		$log.debug "Excluding #{@options[:exclude].inspect}"

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

		ogz=ofile+".gz"
		if @zmeta
			FileUtils.rm_f ofile if File.exists?(ofile)
			File.open(ogz, "w+b") { |fd|
					gz=Zlib::GzipWriter.new(fd, Zlib::DEFAULT_COMPRESSION)
					gz.write json
					gz.close
			}
		else
			FileUtils.rm_f ogz if File.exists?(ogz)
			File.open(ofile, "w+") { |fd|
				fd.write json
			}
		end
	end

	def read_dh(cur_dir)
		backup_dir=@backup_dir+cur_dir
		FileUtils.mkdir_p(backup_dir)
		ifile=backup_dir+GIDDYDATA
		igz=ifile+".gz"

		dir_hash={}
		json=nil

		if File.exists?(ifile)
			json=File.read(ifile)
		elsif File.exists?(igz)
			Zlib::GzipReader.open(igz) { |gz|
				json=gz.read
			}
		end
		dir_hash=JSON.parse(json) unless json.nil?
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
				$log.debug old_hash.inspect
				names=[]
				entries=Dir.glob("{*,.*}")
				entries.each { |dir_entry|
					next if dir_entry.eql?("..")
					break if $stop

					ge=Gentry.new(dir_entry)
					if ge.stat.dir?
						$log.info "Backup dir #{cur_dir}/#{dir_entry}"
						next if is_excluded(dir_entry, :dir)
						@stats[:dir]+=1
						gfind(dir_entry) unless dir_entry.eql?('.')
					elsif ge.stat.file?
						$log.info "Backup file #{cur_dir}/#{dir_entry}"
						next if is_excluded(dir_entry, :file)
						@stats[:file]+=1
						@stats[:bytes]+=ge.stat.size
						save_content=true
						if old_hash.has_key?(dir_entry)
							oge=Gentry.from_hash(old_hash[dir_entry])
							$log.debug "oge="+oge.to_json
							if ge.eql?(oge)
								$log.debug "found entry in old_hash - SAME: #{dir_entry}"
								save_content=false
							else
								$log.debug "found entry in old_hash - DIFFERS: #{dir_entry}"
							end
						else
							oge=nil
						end
						save_content=false if $stop
						ge.save_content(@content_dir) if save_content
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

				write_dh cur_dir, dir_hash unless $stop
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

	def backup

		GiddyUtils.daemonize_app

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
		@stats[:elapsed_time]=1 if @stats[:elapsed_time] <= 0
		@stats[:bps]=@stats[:bytes] / @stats[:elapsed_time]

		# fast JSON streaming (yet another json library)
		# https://github.com/brianmario/yajl-ruby

		$log.info JSON.pretty_generate(@stats)

	end
end


