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
    attr_reader :api, :node_uri

    def initialize(mode, api_url, branch)
      @hostname = Socket.gethostname
      @node_uid, @site_uid, @grid_uid, @ltd = hostname.split(".")
      @cluster_uid = @node_uid.split("-")[0]
      @mode = mode
      if branch == nil
        @branch=""
      else
        @branch="?branch="+branch
      end
      @node_uri = [
        api_url,
        "sites", site_uid,
        "clusters", cluster_uid,
        "nodes", node_uid
      ].join("/")
      @ohai_description = nil
    end

    def api_description
      if @mode == "api"
        @api_description ||= JSON.parse "{}"
      else
        @api_description ||= JSON.parse RestClient.get(@node_uri+@branch, :accept => :json)
      end
      #      @api_description = JSON.parse File.open("files/" + ENV['GRID5000_CHECKS_HOSTNAME'] + ".api","r").read
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
