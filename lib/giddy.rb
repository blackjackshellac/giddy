#!/usr/bin/env ruby

require 'find'
require 'digest/sha1'

rreqdir=File.expand_path(File.dirname(__FILE__))
$:.unshift(rreqdir) unless $:.include?(rreqdir)

require 'giddy/parser'

class Main
	attr_reader :args

	include Giddy

	def initialize
	end

	def parse_args(args)
		parse(args)
	end

	def run
		finder=Find.find('/home/steeve/src')
		finder.each { |file|
			s=File.lstat(file)
			next if s.directory?
			next if s.symlink?
			sha1 = Digest::SHA1.hexdigest(IO.binread(file))
			puts "%s:%s" % [ file, sha1 ]
		}

	end
end

giddy=Main.new
giddy.parse_args(ARGV)
giddy.run


