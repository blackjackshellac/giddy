
require 'digest/sha1'

module Giddy
	# http://www.ruby-doc.org/core-1.9.3/File/Stat.html
	# can't seem to extend File::lstat, just File::Stat, sheet
	class Gstat
		attr_reader :name, :stat

		def initialize(name)
			@stat=File.lstat(name)
			@name=name
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
		def type
			case @stat.ftype
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
			#dev_major,dev_minor,ino,nlinks
			#mode,uid,gid
			#atime,mtime,ctime
			"%s:%s:%s:%s" % [ @stat.size,@stat.blocks,@stat.blksize,type ]
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
		attr_reader :name, :stat, :sha1

		# if stat.directory?
		#  content is the directory listing Dir.glob('{*,.*}'])
		# if stat.file?
		#  content is the file's content, read in block by block
		#  http://www.ruby-doc.org/stdlib-1.9.3/libdoc/digest/rdoc/Digest/HMAC.html#method-i-digest_length
		def initialize(name)
			@name=name
			@stat=Gstat.new(name)
			@sha1=Digest::SHA1.hexdigest(@name)
			puts "Dir=#{name}" if @stat.dir?
		end

		def to_json(*args)
			{
				"name"=>@name,
				"stat"=>@stat.pack,
				"sha1"=>@sha1
			}
		end
	end
end
