#!/usr/bin/ruby
# frozen_string_literal: true

# retrieve nodes configurations on reference API for a cluster and compare them

require 'rubygems'
require 'socket'
require 'restclient'
require 'json'
require 'yaml'

class Cluster
  attr_reader :cluster, :site
  attr_reader :cluster_uri
  attr_reader :remove_attr
  attr_reader :stderr

  def initialize(site, cluster, api_url, test)
    @cluster = cluster
    @site = site
    @test = test
    @remove_attr = %w[serial uid port]
    @cluster_uri = [
      api_url,
      'sites', site,
      'clusters', cluster, 'nodes'
    ].join('/')
    @stderr = []
  end

  def api_description
    if @test
      @api_description = YAML.load_file(File.join("#{@site}-#{@cluster}.yaml"))
    else
      begin
        @api_description = JSON.parse RestClient.get(@cluster_uri, accept: :json)
      rescue StandardError
        @retries ||= 0
        if @retries < 3
          @retries += 1
          sleep 1
          retry
        else
          raise "Fetching #{@cluster_uri} failed too many times..."
        end
      end
    end
    self
  end

  def print_attr(chain, key, uid1, desc1, uid2, desc2)
    return if chain[0] == 'sensors'
    return if chain[0] == 'chassis' && chain[1] == 'serial'

    unless @remove_attr.include?(key)
      @stderr << "Error on [#{chain.join(' - ')}]: #{uid1} with #{desc1} and #{uid2} #{desc2}"
    end
  end

  def diff(chain, uid1, desc1, uid2, desc2)
    if desc1.is_a?(Hash)
      desc1.each_pair do |k, v|
        if desc2[k]
          if v.is_a?(Hash)
            diff(chain + [k], uid1, v, uid2, desc2[k])
          elsif v.is_a?(Array)
            v.each_index do |i|
              diff(chain + [k], uid1, desc1[i], uid2, desc2[i])
            end
          elsif v != desc2[k]
            print_attr(chain + [k], k, uid1, v, uid2, desc2[k])
          end
        end
      end
    elsif desc1.is_a?(Array)
      desc1.each_index do |i|
        diff(chain, uid1, desc1[i], uid2, desc2[i])
      end
    end
  end

  def search_diff
    tmp = @api_description['items'][0]
    @api_description['items'].each do |n|
      diff([], tmp['uid'], tmp, n['uid'], n)
    end
    unless @stderr.empty?
      @stderr.each do |s|
        puts s
      end
      exit 1
    end
  end

  def to_file
    File.open(File.join("#{@site}-#{@cluster}.yaml"), 'w') do |f|
      f.puts @api_description.to_yaml
    end
  end
end

c = ARGV[0].split('-')
clu = Cluster.new(c[0], c[1], 'https://api.grid5000.fr/sid', false).api_description
clu.search_diff
