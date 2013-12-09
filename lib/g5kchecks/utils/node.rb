# retrieve node configuration (with Ohai) and the corresponding API
# caracteristiques.
require 'socket'
require 'restclient'
require 'json'
require 'yaml'
require 'ohai'
Ohai::Config[:plugin_path] << File.join(File.dirname(__FILE__), '/../ohai')

module Grid5000
  class Node
    attr_reader :hostname
    attr_reader :node_uid, :cluster_uid, :site_uid, :grid_uid
    attr_reader :api, :node_uri, :conf

    def initialize(conf)
      @conf = conf
      @hostname = Socket.gethostname
      @node_uid, @site_uid, @grid_uid, @ltd = hostname.split(".")
      @cluster_uid = @node_uid.split("-")[0]
      if conf[:branch] == nil
        @branch=""
      else
        @branch="?branch="+conf[:branch]
      end
      @node_uri = [
        conf[:urlapi],
        "sites", site_uid,
        "clusters", cluster_uid,
        "nodes", node_uid
      ].join("/")
      @ohai_description = nil
    end

    def api_description
      if @conf[:mode] == "api"
        @api_description ||= JSON.parse "{}"
      else
        begin
         @api_description = JSON.parse RestClient.get(@node_uri+@branch, :accept => :json)
        rescue RestClient::ResourceNotFound
          if @conf[:fallback_branch] != nil
            @api_description = JSON.parse RestClient.get(@node_uri+"?branch="+@conf[:fallback_branch], :accept => :json)
          end
        end
        return @api_description
      end
    end

    def get_wanted_mountpoint
	return @conf[:mountpoint] if @conf[:mountpoint] != nil
	return [] 
    end 

    def ohai_description
      if !@ohai_description
        @ohai_description = Ohai::System.new
        @ohai_description.all_plugins
      end
      @ohai_description
    end

  end
end
