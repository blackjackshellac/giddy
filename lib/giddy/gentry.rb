
require 'time'
require 'digest/sha1'

#module Giddy
	# http://www.ruby-doc.org/core-1.9.3/File/Stat.html
	# can't seem to extend File::lstat, just File::Stat, sheet
	class Gstat
		attr_reader :name, :stat
		attr_reader :size, :blocks, :blksize, :dev_major, :dev_minor, :ino, :nlink
		attr_reader :mode, :uid, :gid, :atime, :mtime, :ctime, :ftype

		def initialize(name)
			@name=name
			setup_stats
		end

		# can also do acls or xattrs here
		def setup_stats
			@stat=File.lstat(@name)
			@size=@stat.size
			@blocks=@stat.blocks
			@blksize=@stat.blksize
			@dev_major=@stat.dev_major
			@dev_minor=@stat.dev_minor
			@ino=@stat.ino
			@nlink=@stat.nlink
			@mode=@stat.mode
			@uid=@stat.uid
			@gid=@stat.gid
			@atime=@stat.atime
			@mtime=@stat.mtime
			@ctime=@stat.ctime
			@ftype=@stat.ftype
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
			"%s:%s:%s:%s:0x%02x:0x%02x:%s,%s,0%o,%s,%s,%d,%d,%d" % 
				[ @size,@blocks,@blksize,ftype,@dev_major,@dev_minor,@ino,@nlink,@mode,@uid,@gid,@atime.to_i,@mtime.to_i,@ctime.to_i ]
		end

		def dir?
			@stat.directory?
		end

		def file?
			@stat.file?
		end

		def chardev?
			@stat.chardev?
		end

		def blockdev?
			@stat.blockdev?
		end

		def fifo?
			@stat.fifo?
		end

		def pipe?
			fifo?
		end

		def symlink?
			@stat.symlink?
		end

		def socket?
			@stat.socket?
		end
	end

	class Gentry
		#name - dir entry name
		#stat - dir entry stat object (packed)
		#sha1 - dir entry content sha1
		attr_reader :name, :stat
		attr_accessor :sha1

		# if stat.directory?
		#  content is the directory listing Dir.glob('{*,.*}'])
		# if stat.file?
		#  content is the file's content, read in block by block
		#  http://www.ruby-doc.org/stdlib-1.9.3/libdoc/digest/rdoc/Digest/HMAC.html#method-i-digest_length
		def initialize(name)
			@name=name
			@stat=Gstat.new(name)
			#@sha1=Digest::SHA1.hexdigest(@name)
			@sha1=hexdigest(@name) if @stat.file?
			#puts "Dir=#{name}" if @stat.dir?
		end

		BLKSIZE=4*1024*1024
		def hexdigest(name)
			sha1=Digest::SHA1.new(name)
			return

			sha=Digest::SHA1.new
			sha1=nil
			File.open(name, "rb") { |fd|
				while true
					block=fd.read(BLKSIZE)
					break if block.nil?
					sha1=sha.update(block)
				end
			}
			sha1
		end

		def to_json(*args)
			obj={}
			obj["name"]=@name
			obj["stat"]=@stat.pack
			obj["sha1"]=@sha1
			obj.to_json
		end
	end
#end
