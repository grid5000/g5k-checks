#!/usr/bin/env ruby
$: << File.join(File.dirname(__FILE__))
require 'rubygems'
require 'merge_yaml'
require 'campaign'
require 'optparse'

options = {
  :api=>false,
  :apply_change=>false
}
progname = File::basename($PROGRAM_NAME)
opts = OptionParser::new do |opts|
  opts.program_name = progname
  opts.banner = "Usage: #{progname} [options]"
  opts.separator ''
  opts.separator "Options:"
  opts.on('-s SITE', '--site', 'Site') { |s| options[:site] = s }
  opts.on('-c CLUSTER', '--cluster', 'Cluster') { |c| options[:cluster] = c }
  opts.on('-g', '--get-from-api', 'Get from API') { options[:api] = true }
  opts.on('-n NB_NODES', '--node-number', 'Number of nodes (can put ALL and BEST)') { |n| options[:nb_node] = n }
  opts.on('-r PATH', '--ref-rep', 'Reference-repository git path') { |r| options[:ref_repo] = r }
  opts.on('-a', '--apply-changes', 'Copy new file on api repo (boolean)') { options[:apply_change] = true }
end
opts.parse!(ARGV)

if options[:api] 
  g5kcamp = G5kchecksCampaign.new(options[:site],options[:cluster],options[:nb_node])
  nodes = g5kcamp.run!
  Merge.new(options[:site],options[:cluster],options[:ref_repo],options[:apply_change]).merge! if nodes
else
  Merge.new(options[:site],options[:cluster],options[:ref_repo],options[:apply_change]).merge!
end
