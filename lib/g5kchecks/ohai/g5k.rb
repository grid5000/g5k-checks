
require 'socket'
require 'g5kchecks/utils/utils'

Ohai.plugin(:G5k) do

  provides "g5k"

  collect_data do

    infos = Mash.new

    conf = RSpec.configuration.node.conf

    hostname  = Socket.gethostname
    node_uid, site_uid, grid_uid, ltd = hostname.split(".")
    infos[:node_uid] = node_uid
    infos[:site_uid] = site_uid

    infos["kadeploy"] = {}

    api_base_url = conf["retrieve_url"]

    std_env_name = conf["std_env_name"] || "jessie-x64-std"

    # KADEPLOY environments infos
    begin
      json_envs = JSON.parse(RestClient::Resource.new(api_base_url + "/sites/#{site_uid}/internal/kadeployapi/environments?last=true&user=deploy&name=#{std_env_name}", :user => RSpec.configuration.node.conf["apiuser"], :password => RSpec.configuration.node.conf["apipasswd"]).get()) rescue nil
    end

    if json_envs && json_envs.size == 1
      env = json_envs[0]
      infos["kadeploy"]["stdenv"] = env
    end

    if File.exists?("/etc/grid5000/release")
      File.open("/etc/grid5000/release", "r") do |infile|
        infos["env"] = {}
        infos["env"]["name"] = infile.gets.strip
        infos["env"]["postinstalls"] = infile.gets.strip
      end
    end
    # end KADEPLOY environments infos

    # KADEPLOY node deployment state
    begin
      node_deploy_state = JSON.parse(RestClient::Resource.new(api_base_url + "/sites/#{site_uid}/internal/kadeployapi/nodes/#{hostname}", :user => RSpec.configuration.node.conf["apiuser"], :password => RSpec.configuration.node.conf["apipasswd"]).get()) rescue nil
    end
    if node_deploy_state
      infos["kadeploy"]["user_deployed"] = (node_deploy_state["user"] != "oar")
    end
    # end KADEPLOY deployement infos

    #Sets ohai data
    g5k infos
  end
end
