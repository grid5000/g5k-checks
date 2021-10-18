#!/usr/bin/env ruby
# frozen_string_literal: true

$LOAD_PATH << File.join(File.dirname(__FILE__))
# require 'active_support/ordered_hash'

require 'json'
require 'yaml'

# Hack to enable nested Hashes merging
# Thanks Luc !
class Hash
  def merge!(hash)
    return unless hash.is_a?(Hash)

    hash.each_pair do |k, v|
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
end

class Merge
  def initialize(site, cluster, dir_ref_api, copy)
    @site = site
    @cluster = cluster
    @dir_ref_api = dir_ref_api
    @copy = copy
  end

  def merge_with_another_node(checks_yaml, miss)
    tmp = Marshal.dump(checks_yaml.first[1])
    checks_yaml[miss] = Marshal.load(tmp)
  end

  def full_view(content_hash, sort_tab)
    # Ugly hack to write YAML attribute following a specific order
    yaml = YAML.quick_emit(content_hash) do |out|
      out.map(taguri, to_yaml_style) do |map|
        content_hash.keys.sort do |x, y|
          tmpx = sort_tab.index(x)
          tmpy = sort_tab.index(y)
          if !tmpx && !tmpy
            tmpx = x.to_s
            tmpy = y.to_s
          end
          (tmpx || (max + 1)) <=> (tmpy || (max + 2))
        end.each { |k| map.add(k, content_hash[k]) }
      end
    end
    yaml
  end

  def merge!
    checks = {}

    file_check = File.join(@site, @cluster, 'cluster_check.yaml')
    file_merge = File.join(@site, @cluster, 'cluster_merge_with_admin.yaml')
    File.delete(file_check) if File.exist?(file_check)
    File.delete(file_merge) if File.exist?(file_merge)

    Dir.foreach(File.join(@site, @cluster)) do |x|
      next if (x == '.') || (x == '..')

      node_name = x.split('.')[0]
      checks[node_name.to_s] = JSON.parse(File.read(File.join(@site, @cluster, x)))
    end

    File.open(file_check, 'w') do |f|
      f.puts checks.to_yaml
    end

    admin_yaml = YAML.load_file(File.join(@dir_ref_api, 'generators', 'input', 'sites', @site, 'clusters', @cluster + '_generated.yaml'))
    admin_yaml.merge!(checks)

    if @copy
      File.open(File.join(@dir_ref_api, 'generators', 'input', 'sites', @site, 'clusters', @cluster + '_generated.yaml'), 'w') do |f|
        f.puts admin_yaml.to_yaml
      end
      File.open(file_merge, 'w') do |f|
        f.puts checks.to_yaml
      end
    else
      File.open(file_merge, 'w') do |f|
        f.puts checks.to_yaml
      end
    end
  end
end
