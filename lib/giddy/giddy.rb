#!/usr/bin/env ruby

require 'find'
require 'fileutils'
require 'digest/sha1'
require 'json'
require 'yaml'
require 'benchmark'

rreqdir=File.expand_path(File.dirname(__FILE__))
$:.unshift(rreqdir) unless $:.include?(rreqdir)

require 'parser'
require 'gfile'
require 'gentry'

class Main
	attr_reader :args, :content_dir

	def initialize
		@content_dir="/home/backup/giddy/.content"
		@entry_hash={}
		@entry_cur=@entry_hash
	end

	def parse_args(args)
		parse(args)
	end

#	{
#		"." => ge,
#		".." => ge".",
#		"file" => ge"file",
#		"dir" => {
#			"." => ge(.),
#			".." => ge(..),
#			"foo"=> ge(foo)
#			...
#		}
#	}

	def gfind(dir)
		@entry_last=@entry_cur
		@entry_cur[dir]=Hash.new
		@entry_cur=@entry_cur[dir]

		puts "Changing to #{FileUtils.pwd} #{dir}"
		FileUtils.chdir(dir)
		puts "cwd=#{FileUtils.pwd}"

		entries=Dir.glob("{*,.*}")
		entries.each { |entry|
			next if entry.eql?("..")
			ge=Gentry.new(entry)
			if entry.eql?(".")
				@entry_cur[entry]=ge
			elsif ge.stat.dir?
				gfind(entry)
			else
				@entry_cur[entry]=ge
			end
		}
		# get each entry in this directory list
		names=Array.new
		@entry_cur.each_pair { |name,ge|
			names<<name
		}
		snames=""
		# sort the entries and and create a sha1 hash
		names.sort.each { |name|
			snames<<name
		}
		@entry_cur["."].sha1=Digest::SHA1.new(snames)
		FileUtils.chdir("..")
		@entry_cur=@entry_last
	end

	def run
		gfind('/home/steeve/src')

		puts JSON.pretty_generate(@entry_hash)

		#finder=Find.find('.')
		#finder.each { |entry|
		#	e=Gentry.new(entry)
		#	chdir entry.dir?
		#	puts e.to_json
		#}

	end
end

giddy=Main.new
giddy.parse_args(ARGV)
giddy.run


