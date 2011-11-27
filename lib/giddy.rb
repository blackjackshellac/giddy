#!/usr/bin/env ruby

require 'find'
require 'fileutils'
require 'digest/sha1'

rreqdir=File.expand_path(File.dirname(__FILE__))
$:.unshift(rreqdir) unless $:.include?(rreqdir)

require 'giddy/parser'

class Main
	attr_reader :args, :content_dir

	include Giddy

	def initialize
		@content_dir="/home/backup/giddy/.content"
	end

	def parse_args(args)
		parse(args)
	end

	def run
		finder=Find.find('/home/steeve/src/giddy')
		finder.each { |file|
			s=File.lstat(file)
			case
			when s.directory?
				puts " dir: #{file}"
			when s.file?
				content=IO.binread(file)
				sha1 = Digest::SHA1.hexdigest(content)
#irb(main):013:0> s[/(\w{2})(\w{2})(\w{2})(\w{2})(\w{32})/]
#=> "a381e1e35165c4496ce0cc6e12d23c0a1ba41f1d"
#irb(main):014:0> puts $1+"/"+$2+"/"+$3+"/"+$4+"/"
#a3/81/e1/e3/
#=> nil
#irb(main):015:0> puts $1+"/"+$2+"/"+$3+"/"+$4+"/"+$5
#a3/81/e1/e3/5165c4496ce0cc6e12d23c0a1ba41f1d
#=> nil
				m=sha1[/(\w{2})(\w{2})(\w{2})(\w{2})(\w{32})/]
				if m && m.eql?(sha1)
					sha1_dir="%s/%s/%s/%s/%s" % [ @content_dir, $1, $2, $3, $4, $5 ]
					sha1_file=sha1_dir+"/"+$5
					puts "file: %s:%s" % [ file, sha1_dir ]
					FileUtils.mkdir_p sha1_dir
					File.open(sha1_file, "wb") { |f|
						f.write(content)
					}
				else
					puts "sha1 problem?  #{sha1}"
				end
			when s.symlink?
				puts "syml: #{file}"
			end
		}

	end
end

giddy=Main.new
giddy.parse_args(ARGV)
giddy.run


