#!/usr/bin/env ruby
$: << File.join(File.dirname(__FILE__))
require 'campaign'
require 'merge_yaml'

# $1 site, $2 cluster $3 nb nodes (can put ALL and BEST)
ok = G5kchecksCampaign.new(ARGV[0],ARGV[1],ARGV[2])

MergeYaml.new(ARGV[0],ARGV[1]).merge! if ok
