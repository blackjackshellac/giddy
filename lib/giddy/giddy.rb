#!/usr/bin/env ruby

require 'find'
require 'fileutils'
require 'digest/sha1'
require 'json'
require 'yaml'

rreqdir=File.expand_path(File.dirname(__FILE__))
$:.unshift(rreqdir) unless $:.include?(rreqdir)

require 'parser'
require 'gfile'
require 'gentry'

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
			e=Gentry.new(file)
			puts e.to_json
		}

	end
end

giddy=Main.new
giddy.parse_args(ARGV)
giddy.run


