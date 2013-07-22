#!/usr/bin/env ruby

require 'time'
require 'digest/sha2'
require 'json'

rreqdir=File.expand_path(File.dirname(__FILE__))
$:.unshift(rreqdir) unless $:.include?(rreqdir)

require 'gstat'

# http://www.ruby-doc.org/core-1.9.3/File/Stat.html
# can't seem to extend File::lstat, just File::Stat, sheet
class Gentry
	#name - dir entry name
	#stat - dir entry stat object (packed)
	#sha2 - dir entry content sha2
	attr_reader :name
	attr_accessor :sha2, :stat

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
		if o.nil?
			@stat=Gstat.new(name)
			@sha2=file_sha(@name) if @stat.file?
		elsif o.class == Array
			#puts o.inspect
			@sha2=o[2]
			@stat=Gstat.new(name, o[1])
		elsif o.class == String
			@stat=Gstat.new(name, o)
			@sha2=file_sha(@name) if @stat.file?
		end
	end

	def eql?(other)
		return false if other.nil?
		return false unless @name.eql?(other.name)
		return false unless @sha2.eql?(other.sha2)
		return false if other.stat.nil?
		@stat.eql?(other.stat)
	end

	def file_sha(name)
		sha=Digest::SHA2.new(256)
		File.open(name, "rb") { |fd|
			while true
				block=fd.read(BLKSIZE)
				break if block.nil?
				sha << block
			end
		}
		sha.to_s
	end

	def to_json(*a)
		obj={}
		obj['json_class']=self.class.name
		obj['data']=[ @name, @stat.pack ]
		obj['data'] << @sha2 unless @sha2.nil?
		#obj['name']=@name
		#obj['stat']=@stat.pack
		#obj['sha2']=@sha2
		obj.to_json(*a)
	end

	def self.json_create(o)
		name=o['data'][0]
		new(name, o['data'])
	end

end

#ge=Gentry.new("gentry.rb")
#
#json=ge.to_json
#
#puts json
#
#gs=JSON.parse(json)
#
#puts gs.class
#puts gs.inspect
#puts gs.to_s
#
