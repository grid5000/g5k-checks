#!/usr/bin/env ruby
require 'grid5000/campaign'

class G5kchecksEngine < Grid5000::Campaign::Engine


  on :install! do |env, *args|
    ssh(env[:nodes], "root", :multi => true, :timeout => 10) do |ssh|
        logger.info "enable apt.grid5000.fr and update"
        ssh.exec "sed -i -e \"s/^# deb /deb /\" /etc/apt/sources.list"
        ssh.exec "apt-get update -q2"
    end
    ssh(env[:nodes], "root", :multi => true, :timeout => 10) do |ssh|
        logger.info "install grid5000-keyring"
        ssh.exec "apt-get install grid5000-keyring --force-yes -q2"
    end
    ssh(env[:nodes], "root", :multi => true, :timeout => 10) do |ssh|
        logger.info "install g5kchecks"
        ssh.exec "apt-get install g5kchecks --force-yes -q2"
    end
    env
  end

  on :execute! do |env, *args|
    # execute a specific program on your nodes
    cluster = env[:nodes][0].split(".")[0].split("-")[0]
    Dir.mkdir(File.join(File.dirname(__FILE__),env[:site])) if !File.directory?(File.join(File.dirname(__FILE__),env[:site]))
    Dir.mkdir(File.join(File.dirname(__FILE__),env[:site],cluster)) if !File.directory?(File.join(File.dirname(__FILE__),env[:site],cluster))
    ssh(env[:nodes], "root", :multi => true, :timeout => 10) do |ssh|
        logger.info "execute g5kchecks on all nodes"
        ssh.exec "g5kchecks -p"
    end
    env[:nodes].each { |node|
      ssh(node, "root") do |ssh|
        logger.info "get [#{node}] yaml file"
        ssh.sftp.download!("/tmp/#{node}.yaml", "./#{site}/#{cluster}/#{node}.yaml")
     end
    }
    env
  end

end

class G5kchecksCampaign

  def initialize(site, cluster, nb)

    logger = Logger.new(STDERR)
    logger.level = Logger.const_get("INFO")

    @options = {
      :logger => logger,
      :restfully_config => File.expand_path(
        ENV['RESTFULLY_CONFIG'] || "~/.restfully/api.grid5000.fr.yml"
      )
    }
    @options[:environment] = "wheezy-x64-min"
    @options[:resources] = "nodes=#{nb}"
    @options[:properties] = "cluster='#{cluster}'"
    @options[:walltime] = 3600
    @options[:site] = site
    @options[:name] = "Grid5000 Admin - g5kchecks"

    @options[:no_cleanup] = true
    @options[:no_cancel] = true
    @options[:no_deploy] = true
    @options[:no_submit] = true

    if File.exist?(@options[:restfully_config]) &&
      File.readable?(@options[:restfully_config]) &&
      File.file?(@options[:restfully_config])
      G5kchecksEngine.logger.info "Using Restfully configuration file located at #{@options[:restfully_config]}"

      connection = Restfully::Session.new(
        :configuration_file => @options.delete(:restfully_config),
        :logger => logger
      )

      @options[:gateway] = "access.grid5000.fr"

      engine = G5kchecksEngine.new(connection, @options)
      nodes = engine.run!
      return nodes.size == nb
#      nodes.each {|node| puts node} unless nodes.nil?
    else
      STDERR.puts "Restfully configuration file cannot be loaded: #{@options[:restfully_config].inspect} does not exist or cannot be read or is not a file"
      exit(1)
    end

  end
end

