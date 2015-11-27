#!/usr/bin/env ruby
#
#

require 'digest/sha2'

class Gstat
	attr_reader :name
	attr_reader :size, :blocks, :blksize, :dev_major, :dev_minor, :ino, :nlink
	attr_reader :mode, :uid, :gid, :atime, :mtime, :ctime, :ftype
	attr_reader :stat_sha2

	def initialize(name, stats=nil)
		@name=name
		if stats.nil?
			setup
		else
			unpack(stats)
		end
		@stat_sha2=sha_str(pack)
	end

	def sha_str(str)
		(Digest::SHA2.new(256) << str).to_s
	end

	#		def to_json(*a)
	#			{
	#				'json_class' => self.class.name,
	#				'name' => @name,
	#				'stat' => self.pack
	#			}.to_json(*a)
	#
	#			def self.json_create(o)
	#				new(*o['name'], *o['data'])
	#			end
	#		end

	# can also do acls or xattrs here
	def setup
		lstat=File.lstat(@name)
		@size=lstat.size
		@blocks=lstat.blocks
		@blksize=lstat.blksize
		@dev_major=lstat.dev_major
		@dev_minor=lstat.dev_minor
		@ino=lstat.ino
		@nlink=lstat.nlink
		@mode=lstat.mode
		@uid=lstat.uid
		@gid=lstat.gid
		@atime=lstat.atime
		@mtime=lstat.mtime
		@ctime=lstat.ctime
		@ftype=lstat.ftype
		@ftype=ftype
	end

	def eql?(other)
		return false if other.nil?
		#puts "other.stat="+(other.class)
		true
	end

	#    File: `giddy.rb'
	#    Size: 652       	Blocks: 8          IO Block: 4096   regular file
	#	Device: fd00h/64768d	Inode: 27001063    Links: 1
	#	Access: (0775/-rwxrwxr-x)  Uid: ( 1201/  steeve)   Gid: ( 1201/  steeve)
	#	Context: unconfined_u:object_r:home_root_t:s0
	#	Access: 2011-12-03 07:40:58.796429364 -0500
	#	Modify: 2011-12-03 07:40:57.320416868 -0500
	#	Change: 2011-12-03 07:40:57.365417243 -0500
	#	 Birth: -

	#Identifies the type of stat. The return string is one of:
	#“file”, “directory”, “characterSpecial”, “blockSpecial”, “fifo”, “link”, “socket”, or “unknown”.
	def ftype
		case @ftype
		when "file"
			"f"
		when "directory"
			"d"
		when "characterSpecial"
			"c"
		when "blockSpecial"
			"b"
		when "fifo"
			"p"
		when "link"
			"l"
		when "socket"
			"s"
		else
			"u"
		end
	end

	def pack
		#size,blocks,blksize,ftype
		#dev_major,dev_minor,ino,nlink
		#mode,uid,gid
		#atime,mtime,ctime
		"%s,%s,%s,%s,0x%02x,0x%02x,%s,%s,0%o,%s,%s,%d,%d,%d" %
		[
			@size,
			@blocks,
			@blksize,
			@ftype,
			@dev_major,
			@dev_minor,
			@ino,
			@nlink,
			@mode,
			@uid,
			@gid,
			@atime.to_i,
			@mtime.to_i,
			@ctime.to_i
		]
	end

	def unpack(stats)
		#puts "stats="+stats
		stats=stats.split(/,/)
		#puts stats.inspect
		@size=stats[0].to_i
		@blocks=stats[1].to_i
		@blksize=stats[2].to_i
		@ftype=stats[3]
		@dev_major=stats[4].hex
		@dev_minor=stats[5].hex
		@ino=stats[6].to_i
		@nlink=stats[7].to_i
		@mode=stats[8].oct
		@uid=stats[9].to_i
		@gid=stats[10].to_i
		@atime=stats[11].to_i
		@mtime=stats[12].to_i
		@ctime=stats[13].to_i
	end

	def dir?
		@ftype == "d"
	end

	def file?
		@ftype == "f"
	end

	def chardev?
		@ftype == "c"
	end

	def blockdev?
		@ftype == "b"
	end

	def fifo?
		@ftype == "p"
	end

	def pipe?
		fifo?
	end

	def symlink?
		@ftype == "l"
	end

	def socket?
		@ftype == "s"
	end

	def eql?(other)
		return false if other.nil?
		@stat_sha2.eql?(other.stat_sha2)
	end
end
