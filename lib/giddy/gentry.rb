#!/usr/bin/env ruby

require 'time'
require 'digest/sha2'
require 'json'
require 'tempfile'

rreqdir=File.expand_path(File.dirname(__FILE__))
$:.unshift(rreqdir) unless $:.include?(rreqdir)

require 'gstat'
require 'glogger'

# http://www.ruby-doc.org/core-1.9.3/File/Stat.html
# can't seem to extend File::lstat, just File::Stat, sheet
class Gentry
	#name - dir entry name
	#stat - dir entry stat object (packed)
	#sha2 - dir entry content sha2
	attr_reader :name
	attr_accessor :sha2, :stat
	attr_reader :content_dir, :content_file

	BLKSIZE=4*1024*1024

	# if stat.directory?
	#  content is the directory listing Dir.glob('{*,.*}'])
	# if stat.file?
	#  content is the file's content, read in block by block
	#  http://www.ruby-doc.org/stdlib-1.9.3/libdoc/digest/rdoc/Digest/HMAC.html#method-i-digest_length
	#
	#  name - file/dir/symlink/... name
	#  o    - if Array [ name, packed_stat, sha2 ]
	#  o    - if String - packed_stat (mostly for testing)
	def initialize(name, o=nil)
		raise "name cannot be null" if name.nil?
		@name=name
		@sha2=nil
		if o.nil?
			@stat=Gstat.new(name)
			#@sha2=file_read_op(Digest::SHA2.new(256), @name).to_s if @stat.file?
		elsif o.class == Array
			#puts "o="+o.inspect
			@sha2=o[2]
			@stat=Gstat.new(name, o[1])
		elsif o.class == Hash
			@stat=Gstat.new(name, o["stat"])
			@sha2=o["sha2"] if o.has_key?("sha2")
		elsif o.class == String
			@stat=Gstat.new(name, o)
			#@sha2=file_read_op(Digest::SHA2.new(256), @name).to_s if @stat.file?
		else
			raise "unsupported input parameter class #{o.class}"
		end
		make_content_path
	end

	def eql?(other)
		return false if other.nil?
		return false unless @name.eql?(other.name)
		#return false unless @sha2.eql?(other.sha2)
		return false if other.stat.nil?
		@stat.eql?(other.stat)
	end

	#
	# calculate sha, or write file block by block,
	# depending on the value of op
	#
	# If op.class == Digest::SHA2 updates sha block by block
	# If op.class == File write to file block by block
	def file_read_op(op, name=nil)
		name=@name if name.nil?
		sha2=Digest::SHA2.new(256)
		File.open(name, "rb") { |fd|
			while true
				block=fd.read(BLKSIZE)
				break if block.nil?
				op << block
				sha2 << block
			end
		}
		@sha2=sha2.to_s
		op
	end

	def make_content_path
		return if @sha2.nil?
		# split the sha1 string into four 2 character directories and a 64-(4*2)=56 character file
		#puts "sha2="+@sha2
		m=@sha2[/(\w{2})(\w{2})(\w{2})(\w{2})(\w+)/]
		if m && m.eql?(@sha2)
			@content_dir="%s/%s/%s/%s" % [ $1, $2, $3, $4 ]
			@content_file=$5
		else
			raise "Failed to split sha2=#{@sha2}"
		end
		#puts "content="+@content_dir+"/"+@content_file
	end

	def save_content(backup_dir, force=false)
		#backup_dir="%s/%s" % [ backup_dir, @content_dir ]
		#backup_file="%s/%s" % [ backup_dir, @content_file ]
		#if File.exists?(backup_file)
		#	$log.debug "content file already exists: #{backup_file}"
		#else
		#	$log.debug "content file=#{backup_file}"
		#	FileUtils.mkdir_p backup_dir
		#	File.open(backup_file, "w+b") { |fd|
		#		file_read_op(fd)
		#	}
		#end
		tmpname=Dir::Tmpname.make_tmpname @name, nil
		tmp_backup="%s/%s" % [ backup_dir, tmpname ]
		$log.debug "tmp content file=#{tmp_backup}"
		File.open(tmp_backup, "w+b") { |fd|
			file_read_op(fd)
		}

		# create sha2 for the file just copied
		make_content_path

		backup_dir="%s/%s" % [ backup_dir, @content_dir ]
		content_path="%s/%s" % [ backup_dir, @content_file ]
		if File.exists?(content_path)
			if force
				$log.warn "backup file already exists, replacing its content: #{content_path}"
				FileUtils.rm_f content_path
			else
				$log.debug "backup content exists, don't update content: #{content_path}"
			end
		end
		unless File.exists?(content_path)
			$log.debug "mkdir_p #{backup_dir}"
			FileUtils.mkdir_p backup_dir
			$log.debug "mv #{tmp_backup} #{content_path}"
			FileUtils.mv tmp_backup, content_path
		end
	end

	def to_json(*a)
		o={
			:name=>@name,
			:stat=>@stat.pack
		}
		o[:sha2] = @sha2 unless @sha2.nil?
		o.to_json(*a)
	end

	def self.from_json(j)
		o=JSON.parse(j)
		from_hash(o) #new(o["name"], o)
	end

	def self.from_hash(o)
		new(o["name"], o)
	end

end

