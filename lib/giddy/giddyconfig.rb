
require 'readline'

rreqdir=File.expand_path(File.dirname(__FILE__))
$:.unshift(rreqdir) unless $:.include?(rreqdir)

require 'giddyutils'
require 'glogger'

class GiddyConfig
	attr_reader :backup_dir, :content_dir, :stats, :backups, :compress
	attr_reader :admin, :file, :log_dir

	def initialize
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
		@compress={
			:metadata=>true,
			:content=>false
		}

		@backups=[]

		@admin=(Process.uid == 0)
		if @admin
			@log_dir="/var/log/giddy"
			@file="/etc/giddy/giddy.conf"
		else
			@log_dir="/tmp/giddy/log"
			@file="#{ENV['HOME']}/.giddyconf"
		end

		set_logger(STDOUT, Logger::INFO)

		$log.debug @backup_dir
		$log.debug @content_dir
		$log.debug @stats.inspect
		$log.debug @backups.inspect
		$log.debug @file
		$log.debug @log_dir

		load_config
	end

	def to_bool(val, default)
		return default if val.empty?
		return true if val =~ (/(true|t|yes|y|1)$/i)
		return false if val =~ (/(false|f|no|n|0)$/i)
		raise ArgumentError.new("invalid value for Boolean: \"#{val}\"")
	end

	def read(prompt, default)
		begin
			p="%s [%s] > " % [ prompt, default ]
			r=Readline.readline(p, true).strip
			case default
			when String
				r=default if r.empty?
			when TrueClass, FalseClass
				r=to_bool(r, default)
			else
				raise "unknown default type #{default.class}"
			end
			$log.debug "r=#{r}"
		rescue Interrupt
			#system("stty", stty_save)
			exit 1
		end
		r
	end

	def init
		@backup_dir=(read "Backup directory", @backup_dir).chomp("/")
		@content_dir=(read "Content directory", "#{@backup_dir}/.content").chomp("/")
		@log_dir=(read "Log directory", @log_dir).chomp("/")
		@compress[:metadata]=(read "Compress metadata", @compress[:metadata])
		@compress[:content]=(read "Compress content",  @compress[:content])
		save_config
	end

	def load_config
		unless File.exists?(@file)
			$log.warn "Giddy backup config file not set yet #{@file}, run --init"
			return
		end
		json=File.read(@file)
		unhash_config(json)
	end

	def save_config
		h=hash_config
		File.open(@file, "w+") { |fd|
			fd.write(JSON.pretty_generate(h))
		}
		$log.info "Saved config to #{@file}"
	end

	def unhash_val(h, key, default)
		h.has_key?(key) ? h[key] : default
	end

	def unhash_config(json)
		begin
			h=JSON.parse(json, :symbolize_names=>true)
			$log.debug "h="+h.inspect
			@backup_dir=unhash_val(h, :backup_dir, @backup_dir)
			@content_dir=unhash_val(h, :content_dir, @content_dir)
			@log_dir=unhash_val(h, :log_dir, @log_dir)
			@backups=unhash_val(h, :backups, @backups)
			@compress=unhash_val(h, :compress, @compress)
		rescue
			$log.error "Failed to parse config: json=#{json}"
		end
	end

	def hash_config
		{
			:backup_dir=>@backup_dir,
			:content_dir=>@content_dir,
			:log_dir=>@log_dir,
			:backups=>@backups,
			:compress=>@compress
		}
	end
end

