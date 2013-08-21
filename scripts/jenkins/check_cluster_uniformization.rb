#!/usr/bin/ruby
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

  def initialize(site,cluster,api_url,test)
    @cluster = cluster
    @site = site
    @test = test
    @remove_attr = ["serial","uid","port"]
    @cluster_uri = [
      api_url,
      "sites", site,
      "clusters", cluster,"nodes"
    ].join("/")
    @stderr = []
  end

  def api_description
    if @test
      @api_description =  YAML.load_file(File.join("#{@site}-#{@cluster}.yaml"))
    else
      @api_description = JSON.parse RestClient.get(@cluster_uri, :accept => :json)
    end
    self
  end

  def print_attr(chain,key,uid1,desc1,uid2,desc2)
    if !@remove_attr.include?(key)
      if key == "ram_size"
         @stderr << "Error on [#{chain.join(" - ")}]: #{uid1} with #{desc1} and #{uid2} #{desc2}" if desc2/100000000 != desc1/100000000
      elsif key == "clock_speed"
        err = (desc2-desc1).abs
         @stderr << "Error on [#{chain.join(" - ")}]: #{uid1} with #{desc1} and #{uid2} #{desc2}" if err > 100000000
      else
         @stderr << "Error on [#{chain.join(" - ")}]: #{uid1} with #{desc1} and #{uid2} #{desc2}"
      end
    end
  end

  def diff(chain,uid1,desc1,uid2,desc2)
    if desc1.is_a?(Hash)
      desc1.each_pair do |k,v|
        if desc2[k]
          if v.is_a?(Hash)
            diff(chain + [k],uid1,v,uid2,desc2[k])
          elsif v.is_a?(Array)
            v.each_index do |i|
              diff(chain + [k],uid1,desc1[i],uid2,desc2[i])
            end
          elsif v != desc2[k]
            print_attr(chain + [k], k,uid1,v,uid2,desc2[k])
          end
        end
      end
    elsif desc1.is_a?(Array)
      desc1.each_index do |i|
        diff(chain,uid1,desc1[i],uid2,desc2[i])
      end
    end
  end

  def search_diff
    tmp = @api_description['items'][0]
    @api_description['items'].each{|n|
      diff([],tmp['uid'],tmp,n['uid'],n)
    }
    if @stderr.size > 0
      @stderr.each{|s|
        puts s
      }
      exit 1
    end
  end

  def to_file
    File.open(File.join("#{@site}-#{@cluster}.yaml"), 'w' ) { |f|
      f.puts @api_description.to_yaml
    }
  end

end

c = ARGV[0].split("-")
clu = Cluster.new(c[0],c[1], 'https://api.grid5000.fr/sid',false).api_description
clu.search_diff
