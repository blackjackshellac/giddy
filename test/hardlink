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
		@stats={
			:bytes=>0,
			:bps=>0,
			:files=>0,
			:dirs=>0
		}
		@options={}
	end

	def parse_args(args)
		@options=parse(args)
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

		begin
			FileUtils.chdir(dir)
		rescue
			puts ":"+dir.class.to_s
			if dir[/^\//]
				puts "Failed to change to #{dir}"
			else
				puts "Failed to change to #{FileUtils.pwd}/#{dir}"
			end
			return
		end

		puts "Changed to #{FileUtils.pwd}"

		names=Array.new
		entries=Dir.glob("{*,.*}")
		entries.each { |entry|
			next if entry.eql?("..")
			names<<entry
			puts "  entry=.../#{dir}/#{entry}"
			ge=Gentry.new(entry)
			if ge.stat.dir?
				@stats[:dirs]+=1
				if entry.eql?('.')
					@entry_cur[entry]=ge
				else
					gfind(entry)
				end
			elsif ge.stat.file?
				@stats[:files]+=1
				@stats[:bytes]+=ge.stat.size
			else
				@entry_cur[entry]=ge
			end
		}
		# get each entry in this directory list
		#names=Array.new
		#@entry_cur.each_pair { |name,ge|
		#	names<<name
		#}
		snames=""
		# sort the entries and and create a sha1 hash
		names.sort.each { |name|
			snames<<name+","
		}
		snames.chop!
		puts "  . #{snames}"
		@entry_cur["."].sha1=Digest::SHA1.new(snames)
		FileUtils.chdir("..")
		@entry_cur=@entry_last
	end

	def run
		@options[:include].each { |inc|
			@entry_hash={}
			gfind(inc)
		}

		puts JSON.pretty_generate(@stats)
		#puts JSON.pretty_generate(@entry_hash)
		#puts @entry_hash.to_yaml
		#puts @entry_hash.to_json
		#puts @entry_hash.to_s

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

