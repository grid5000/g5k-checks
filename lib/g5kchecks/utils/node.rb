# retrieve node configuration (with Ohai) and the corresponding API
# characteristics.
require 'socket'
require 'restclient'
require 'json'
require 'yaml'
require 'ohai'

Ohai.config[:plugin_path] << File.expand_path(File.join(File.dirname(__FILE__), '/../ohai'))

module Grid5000
  class Node
    attr_reader :hostname
    attr_reader :node_uid, :cluster_uid, :site_uid, :grid_uid
    attr_reader :api, :node_path, :conf

    def initialize(conf)
      @conf = conf
      @hostname = Socket.gethostname
      @node_uid, @site_uid, @grid_uid, @ltd = hostname.split(".")
      @cluster_uid = @node_uid.split("-")[0]
      @ohai_description = nil
      @api_description = nil
      @max_retries = 2
    end

    def api_description
      return @api_description if @api_description != nil
      if @conf["mode"] == "api"
        @api_description = JSON.parse "{}"
      elsif @conf["retrieve_from"] == "rest"
        if conf["branch"] == nil
          @branch=""
        else
          @branch="?branch="+conf["branch"]
        end
        @node_path = [
          conf["retrieve_url"],
          "sites", site_uid,
          "clusters", cluster_uid,
          "nodes", node_uid
        ].join("/")
        begin
          @api_description = JSON.parse RestClient::Resource.new(@node_path+@branch, :user => @conf["apiuser"], :password => @conf["apipasswd"], :headers => {
                                                                   :accept => :json
                                                                 }).get()
        rescue RestClient::ResourceNotFound
          if @conf["fallback_branch"] != nil
            begin
              @api_description = JSON.parse RestClient::Resource.new(@node_path+"?branch="+@conf["fallback_branch"], :user => @conf["apiuser"], :password => @conf["apipasswd"], :headers => {
                                                                       :accept => :json
                                                                     }).get()
            rescue RestClient::ResourceNotFound
              raise "Node not found with url #{@node_path+@branch} and #{@node_path+"?branch="+@conf["fallback_branch"]}"
            rescue RestClient::ServiceUnavailable => error
              @retries ||= 0
              if @retries < @max_retries
                @retries += 1
                sleep 10
                retry
              else
                raise error
              end
            end
          else
            raise "Node not find with url #{@node_path+@branch}"
          end
        rescue RestClient::ServiceUnavailable => error
          @retries ||= 0
          if @retries < @max_retries
            @retries += 1
            sleep 10
            retry
          else
            raise error
          end
        end
      elsif @conf["retrieve_from"] == "file"
	@node_path = File.join(@conf["retrieve_dir"], @hostname+".json") 
	@api_description = JSON.parse(File.read(@node_path))	
      end
      return @api_description
    end

    def get_wanted_mountpoint
	return @conf["mountpoint"] if @conf["mountpoint"] != nil
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
