#!/usr/bin/env ruby

rreqdir=File.expand_path(File.dirname(__FILE__))
$:.unshift(rreqdir) unless $:.include?(rreqdir)

require 'giddy/parser'

class Giddy
	attr_reader :args

	def initialize
		@args=args
	end

	def parse_args
		Giddy::parser(@args)
	end

	def run
	end
end

giddy=Giddy.new #(ARGV)
giddy.parse_args
giddy.run

