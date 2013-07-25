
require 'readline'

rreqdir=File.expand_path(File.dirname(__FILE__))
$:.unshift(rreqdir) unless $:.include?(rreqdir)

require 'giddyutils'
require 'glogger'

class GiddyConfig
	attr_reader :backup_dir, :content_dir, :stats, :backups
	attr_reader :admin, :file

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

		@backups=[]

		@admin=(Process.uid == 0)

		@file=@admin ? "/etc/giddy/giddy.conf" : "#{ENV['HOME']}/.giddyconf"

		set_logger(STDOUT, Logger::INFO)

		$log.debug @backup_dir
		$log.debug @content_dir
		$log.debug @stats.inspect
		$log.debug @backups.inspect
		$log.debug @file

		load
	end

	def read(prompt, default)
		begin
			p="%s [%s] > " % [ prompt, default ]
			r=Readline.readline(p, true).strip
			$log.debug "r=#{r}"
			r=default if r.nil? || r.empty?
			r
		rescue Interrupt
			#system("stty", stty_save)
			exit 1
		end
	end

	def init
		@backup_dir=(read "Backup directory", @backup_dir).chomp("/")
		@content_dir=(read "Content directory", "#{@backup_dir}/.content").chomp("/")
		save
	end

	def load
		unless File.exists?(@file)
			$log.warn "Giddy backup config file not set yet #{@file}, run --init"
			return
		end
		json=File.read(@file)
		unhash_config(json)
	end

	def save
		h=hash_config
		File.open(@file, "w+") { |fd|
			fd.write(JSON.pretty_generate(h))
		}
		$log.info "Saved config to #{@file}"
	end

	def unhash_config(json)
		h=JSON.parse(json, :symbolize_names=>true)
		$log.debug "h="+h.inspect
		#@backup_dir=h[:backup_dir]
		#@content_dir=h[:content_dir]
		#@backups=h[:backups]
	end

	def hash_config
		{
			:backup_dir=>@backup_dir,
			:content_dir=>@content_dir,
			:backups=>@backups
		}
	end
end

