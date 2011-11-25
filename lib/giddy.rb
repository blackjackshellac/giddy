#!/usr/bin/env ruby

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
	end
end

giddy=Main.new
giddy.parse_args(ARGV)
giddy.run


