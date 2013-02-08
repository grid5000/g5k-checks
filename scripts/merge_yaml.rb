#!/usr/bin/env ruby
$: << File.join(File.dirname(__FILE__))

# Hack to enable nested Hashes merging
# Thanks Luc !
class Hash
  def merge!(hash)
    return unless hash.is_a?(Hash)
    hash.each_pair do |k,v|
      if self[k]
        if v.is_a?(Hash)
          self[k].merge!(v)
        elsif v.is_a?(Array)
          # Keep array's order
          v.each_index do |i|
            self[k][i] = v[i] unless v[i].nil?
          end
        else
          self[k] = v
        end
      else
        self[k] = v
      end
    end
  end

  def merge(hash)
    ret = self.dup
    return ret unless hash.is_a?(Hash)
    hash.each_pair do |k,v|
      if ret[k]
        if v.is_a?(Hash)
          ret[k] = ret[k].merge(v)
        elsif v.is_a?(Array)
          # Keep array's order
          v.each_index do |i|
            ret[k][i] = v[i] unless v[i].nil?
          end
        else
          ret[k] = v
        end
      else
        ret[k] = v
      end
    end
    ret
  end
end

class MergeYaml

  def initialize(site, cluster, file_merge)
    @site = site
    @cluster = cluster
    @file_merge = file_merge
  end

  def merge!
    checks_yaml = {}
    Dir.foreach(File.join(ARGV[0],ARGV[1])) {|x|
      next if x == '.' or x == '..'
      node_name = x.split(".")[0]
      checks_yaml["#{node_name}"] = YAML.load_file(File.join(ARGV[0],ARGV[1],x))["#{x}"]
   }

    file_check = File.join(ARGV[0],ARGV[1], "cluster_check.yaml")
    file_merge = File.join(ARGV[0],ARGV[1], "cluster_merge_with_admin.yaml")
    File.delete(file_check) if File.exist?(file_check)
    File.delete(file_merge) if File.exist?(file_merge)
    File.open(file_check, 'w') { |f|
      f.puts checks_yaml.to_yaml
    }

    admin_yaml = YAML.load_file(@file_merge)
    checks_yaml.merge!(admin_yaml)

    File.open(file_merge, 'w') { |f|
      f.puts checks_yaml.to_yaml
    }

  end

end
