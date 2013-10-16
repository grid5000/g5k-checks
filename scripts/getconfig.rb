#!/usr/bin/env ruby
$: << File.join(File.dirname(__FILE__))
require 'rubygems'
require 'merge_yaml'
require 'campaign'

# $1 site, $2 cluster $3 nb nodes (can put ALL and BEST), $4 reference-repository directory $5 copy new file on api repo (boolean)
if ARGV.size != 5
  puts 'pas les bons arguments'
  exit 1
end
g5kcamp = G5kchecksCampaign.new(ARGV[0],ARGV[1],ARGV[2])

nodes = g5kcamp.run!

Merge.new(ARGV[0],ARGV[1], ARGV[3],ARGV[4]).merge! if nodes
