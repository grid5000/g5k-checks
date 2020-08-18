#!/usr/bin/env ruby
# frozen_string_literal: true

$LOAD_PATH << File.join(File.dirname(__FILE__))
require 'grid5000/campaign'

class G5kchecksEngine < Grid5000::Campaign::Engine
  on :install! do |env, *_args|
    ssh(env[:nodes], 'root', multi: true, timeout: 10) do |ssh|
      ssh.exec 'modprobe ipmi_devintf && modprobe ipmi_si && modprobe ipmi_msghandler'
      ssh.exec 'apt-get install ipmitool -y '
      ssh.exec 'apt-get install -f'
      ssh.exec 'export PATH=/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin:/usr/local/games:/usr/games && g5k-checks -m api'
      puts ssh.exec 'ls /tmp/'
    end
    env
  end

  on :execute! do |env, *_args|
    # execute a specific program on your nodes
    cluster = env[:nodes][0].split('.')[0].split('-')[0]
    unless File.directory?(File.join(File.dirname(__FILE__), env[:site]))
      Dir.mkdir(File.join(File.dirname(__FILE__), env[:site]))
    end
    unless File.directory?(File.join(File.dirname(__FILE__), env[:site], cluster))
      Dir.mkdir(File.join(File.dirname(__FILE__), env[:site], cluster))
    end
    ssh(env[:nodes], 'root', multi: true, timeout: 10) do |ssh|
      ssh.exec 'export PATH=/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin:/usr/local/games:/usr/games && g5k-checks -m api'
    end
    env[:nodes].each do |node|
      ssh(node, 'root') do |ssh|
        logger.info "get [#{node}] json file"
        ssh.sftp.download!("/tmp/#{node}.json", "./#{site}/#{cluster}/#{node}.json")
      end
    end
    env
  end
end

class G5kchecksCampaign
  def initialize(site, cluster, nb)
    @logger = Logger.new(STDERR)
    @logger.level = Logger.const_get('INFO')

    @options = {
      logger: @logger,
      restfully_config: File.expand_path(
        ENV['RESTFULLY_CONFIG'] || '~/.restfully/api.grid5000.fr.yml'
      )
    }
    @options[:environment] = 'wheezy-x64-prod'
    @options[:resources] = "nodes=#{nb}"
    @options[:properties] = "cluster='#{cluster}'"
    @options[:walltime] = 3600
    @options[:site] = site
    @options[:name] = 'Grid5000 Admin - g5kchecks'
    @options[:deployment_min_threshold] = 0.5

    @options[:no_cleanup] = true
    @options[:no_cancel] = true
    @options[:no_deploy] = false
    @options[:no_submit] = true
    @options[:gateway] = "#{site}.g5k"
    @nb = nb
  end

  def run!
    if File.exist?(@options[:restfully_config]) &&
       File.readable?(@options[:restfully_config]) &&
       File.file?(@options[:restfully_config])
      G5kchecksEngine.logger.info "Using Restfully configuration file located at #{@options[:restfully_config]}"

      connection = Restfully::Session.new(
        configuration_file: @options.delete(:restfully_config),
        logger: @logger
      )

      engine = G5kchecksEngine.new(connection, @options)
      nodes = engine.run!
      return false if nodes.nil?

      true
    else
      warn "Restfully configuration file cannot be loaded: #{@options[:restfully_config].inspect} does not exist or cannot be read or is not a file"
      exit(1)
    end
  end
end
