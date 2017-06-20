
require 'socket'
require 'g5kchecks/utils/utils'

Ohai.plugin(:G5k) do

  provides "g5k"

  collect_data do

    infos = Mash.new

    conf = RSpec.configuration.node.conf
    hostname  = Socket.gethostname
    #node_uid, site_uid, grid_uid, ltd = hostname.split(".")
    #TODO for tests, remove
    node_uid, site_uid, grid_uid, ltd = "edel-34.grenoble.grid5000.fr".split(".")
    infos[:node_uid] = node_uid
    infos[:site_uid] = site_uid

    api_base_url = conf["retrieve_url"]

    #Get kadeploy environments infos
    begin
      json_envs = JSON.parse(RestClient::Resource.new(api_base_url + "/sites/#{site_uid}/internal/kadeployapi/environments?last=true&user=deploy", :user => RSpec.configuration.node.conf["apiuser"], :password => RSpec.configuration.node.conf["apipasswd"]).get())
    end

    if json_envs && json_envs.size > 0
      json_envs.sort_by{|env| - env["version"]}.each{ |env|
        #Get last std env definition
        if (env['name'].end_with?("-std"))
          infos["kadeploy"] = {}
          infos["kadeploy"]["stdenv"] = env
          break
        end
      }
    end

    if File.exists?("/etc/grid5000/release")
      File.open("/etc/grid5000/release", "r") do |infile|
        infos["env"] = {}
        infos["env"]["name"] = infile.gets.strip
        infos["env"]["postinstalls"] = infile.gets.strip
      end
    end

    #Sets ohai data
    g5k infos
  end
end
