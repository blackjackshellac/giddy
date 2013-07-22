
require 'digest/sha1'

#module Giddy
	class GFile < File
		attr_reader :content, :content_sha1, :content_dir, :content_file
		attr_reader :file, :path, :stat

		def initialize(path)
			@file=super(path)
			@path=path
			@stat=file.lstat
			@content_sha1=nil
			@content_dir=nil
			@content_file=nil
		end

		def content
			# need to iteratively read and hash the content for large
			# files
			@content=@file.read
			@content_sha1=Digest::SHA1.hexdigest(@content)
			#
			# split the sha1 string into four 2 character directories and a 32 character file
			m=@content_sha1[/(\w{2})(\w{2})(\w{2})(\w{2})(\w{32})/]
			if m && m.eql?(@content_sha1)
				@content_dir="%s/%s/%s/%s/%s" % [ @content_dir, $1, $2, $3, $4, $5 ]
				@content_file=@content_dir+"/"+$5
			end
			@content_sha1
		end

		def save_content(backup_dir)
			backup_dir="%s/%s" % [ backup_dir, @content_dir ]
			$stdout.puts backup_dir #"file: %s => %s/%s" % [ @path, backup_dir, @content_file ]
			FileUtils.mkdir_p backup_dir
			File.open(backup_dir+"/"+@content_file, "wb") { |f|
				f.write(@content)
			}
		end

		def directory?
			@stat.directory?
		end

		def file?
			@stat.file?
		end

		def symlink?
			@stat.symlink?
		end
	end
#end
