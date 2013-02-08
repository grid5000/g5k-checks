#!/usr/bin/env ruby
$: << File.join(File.dirname(__FILE__))
require 'campaign'
require 'merge_yaml'

# $1 site, $2 cluster $3 nb nodes (can put ALL and BEST), $4 file to merge
if ARGV.size != 4
  puts 'pas les bons arguments'
  exit 1
end
ok = G5kchecksCampaign.new(ARGV[0],ARGV[1],ARGV[2])

MergeYaml.new(ARGV[0],ARGV[1], ARGV[3]).merge! if ok
