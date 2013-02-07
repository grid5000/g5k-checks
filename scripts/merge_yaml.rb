#!/usr/bin/env ruby
$: << File.join(File.dirname(__FILE__))


class MergeYaml

  def initialize(site, cluster)
    @site = site
    @cluster = cluster
  end

  def merge!
    cluster = {}
    Dir.foreach(File.join(ARGV[0],ARGV[1])) {|x|
      next if x == '.' or x == '..'
      cluster[x] = YAML.load_file(File.join(ARGV[0],ARGV[1],x))
    }

    File.open(File.join(ARGV[0],ARGV[1], "cluster.yaml"), 'w') { |f|
      f.puts cluster.to_yaml
    }
  end

end
