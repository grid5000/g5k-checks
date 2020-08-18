# frozen_string_literal: true

require 'socket'
require 'g5kchecks/utils/utils'

Ohai.plugin(:G5k) do
  provides 'g5k'

  collect_data do
    infos = Mash.new

    conf = RSpec.configuration.node.conf

    hostname = Socket.gethostname
    node_uid, site_uid, _grid_uid, _ltd = hostname.split('.')
    infos[:node_uid] = node_uid
    infos[:site_uid] = site_uid

    infos['kadeploy'] = {}

    api_base_url = conf['retrieve_url']

    # KADEPLOY environments infos
    if conf['mode'] != 'api'
      ref_api = RSpec.configuration.node.api_description['software']
      std_env_name = ref_api['standard-environment']
      json_envs = Utils.api_call(api_base_url + "/sites/#{site_uid}/internal/kadeployapi/environments?last=true&user=deploy&name=#{std_env_name}")

      if json_envs.size == 1
        infos['kadeploy']['stdenv'] = json_envs[0]
      else
        raise 'More than one environment returned by Kadeploy API'
      end

      if File.exist?('/etc/grid5000/release')
        File.open('/etc/grid5000/release', 'r') do |infile|
          infos['env'] = {}
          infos['env']['name'] = infile.gets.strip
        end
      end

      if File.exist?('/etc/grid5000/postinstall')
        json_postinstall = JSON.load(File.open('/etc/grid5000/postinstall', 'r'))
        infos['postinstall'] = {}
        infos['postinstall']['version'] = json_postinstall['version']
      end

      if File.exist?('/etc/grid5000/forced-deployment-timestamp')
        File.open('/etc/grid5000/forced-deployment-timestamp', 'r') do |infile|
          infos['forced-deployment-timestamp'] = infile.gets.strip.to_i
        end
      end
    end
    # end KADEPLOY environments infos

    # infos['user_deployed'] is true if the environment is deployed
    # inside a job (in particular, this excludes phoenix), and the job
    # is of type 'deploy'
    json_job = nil
    json_status = Utils.api_call(api_base_url + "/sites/#{site_uid}/status?disks=no&waiting=no&network_address=#{hostname}")

    # If the environment is deployed inside a job
    if !json_status.nil? && json_status['nodes'] != {} && json_status['nodes'][hostname]['hard'] == 'alive' && json_status['nodes'][hostname]['soft'] != 'free'
      job_id = json_status['nodes'][hostname]['reservations'].select { |e| e['state'] == 'running' }.first['uid']
      json_job = Utils.api_call(api_base_url + "/sites/#{site_uid}/jobs/#{job_id}")
    else
      json_job = nil
    end

    if json_job.nil?
      infos['user_deployed'] = false
    else
      # Test if the job is of type 'deploy'
      infos['user_deployed'] = json_job['types'].include?('deploy')
      infos['disks'] = if json_job['resources_by_type']['disks'].nil?
                         ['sda']
                       else
                         # sda + reserved_disks
                         ['sda'] + json_job['resources_by_type']['disks'].map { |e| e.split('.').first }
                       end
    end

    # Sets ohai data
    g5k infos
  end
end
