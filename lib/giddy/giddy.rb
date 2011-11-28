#!/usr/bin/env ruby

require 'find'
require 'fileutils'
require 'digest/sha1'

rreqdir=File.expand_path(File.dirname(__FILE__))
$:.unshift(rreqdir) unless $:.include?(rreqdir)

require 'parser'
require 'gfile'

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
			#s=File.lstat(file)
			s=GFile.new(file)
			case
			when s.directory?
				puts " dir: #{file}"
			when s.file?
				s.content
				s.save_content(@content_dir)
			when s.symlink?
				puts "syml: #{file}"
			end
		}

	end
end

giddy=Main.new
giddy.parse_args(ARGV)
giddy.run


