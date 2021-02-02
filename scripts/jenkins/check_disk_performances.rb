#!/usr/bin/env ruby
# frozen_string_literal: true

$LOAD_PATH << File.join(File.dirname(__FILE__))
STDERR.reopen(STDOUT)

require 'rubygems'
require 'yaml'
require 'json'
require 'restfully'
require 'fileutils'
require 'timeout'
require 'optparse'
require 'pp'
require 'net/ssh/gateway'
require 'net/sftp'

require 'JobManager.rb'

logger = Logger.new(STDOUT)
logger.level = Logger::INFO

options = { 'logger' => logger, 'shell' => false, :'kadeploy3-timeout' => 8 * 60 }

job_manager = JobManager.new

options.merge!(job_manager.default_options)

option_parser = OptionParser.new do |opts|
  opts.banner = <<~BANNER
    * Description
      deploy a environment on a given cluster, after having made the necessary reservation
    * Usage
      deploy.rb [options]
  BANNER

  opts.on('--deploy-timeout MANDATORY', 'Time before considering it is not possible to deploy the resources needed by this script. This timeout only guards the deployments step') do |v|
    options[:'kadeploy3-timeout'] = v.to_i
  end

  opts.on('-e ENV', '--kaenv ENV', 'Name or url of the environment to deploy') do |v|
    options[:kaenv] = v
  end

  opts.separator ''
  opts.separator '* Common options'
  opts.on('-k', '--ssh-key SSH_KEY', 'ssh public key to use to connect to deployed nodes') do |v|
    options[:'ssh-key'] = v
  end
  opts.on('-v', '--verbose', 'Run verbosely') do |_v|
    options['logger'].level = Logger::INFO
  end
  opts.on('-d', '--debug', 'Run in debug mode') do |_v|
    options['logger'].level = Logger::DEBUG
  end
  opts.on('--restfully-file YAML_FILE', 'Restfully yaml conf file. ~/.restfully/api.grid5000.fr.yml used by default') do |v|
    options[:'yaml-conf'] = v
  end

  opts.on('--cmd CMD', 'command to run after deploy') do |v|
    options[:cmd] = v
  end

  opts.on('-h', '--help', 'Show this message') do
    puts opts
    exit
  end
  opts.on('-v', '--version', 'Show version') do
    puts 0.1
    exit
  end
end

job_manager.add_parser_options(option_parser, options)

option_parser.parse!

options[:'ssh-key'] = "~/.ssh/grid5000keys/id_rsa_#{options[:site]}.pub" if options[:'ssh-key'].nil?

siteg5k = options[:site]
envg5k = options[:kaenv]

options[:'yaml-conf'] = '~/.restfully/api.grid5000.fr.yml' if options[:'yaml-conf'].nil?
config = YAML.safe_load(File.open(File.expand_path(options[:'yaml-conf'])))

pp siteg5k
@site = siteg5k
@cmd = options[:cmd]
polling_frequency = 25
@mutex = Mutex.new
@retval = 0
@deployments = []
@jobs = []

PUBLIC_KEY = File.expand_path(options[:'ssh-key'])
PRIVATE_KEY = File.expand_path("~/.ssh/#{File.basename((options[:'ssh-key']).to_s, '.pub')}")

logger = Logger.new(STDOUT)
logger.level = Logger::INFO

def deployment_ok?(deployment)
  return false if deployment.nil?
  return false if %w[canceled error].include? deployment['status']

  nodes_ok = begin
               deployment['result'].values.count do |v|
                 v['state'] == 'OK'
               end
             rescue StandardError
               0
             end
  nodes_ok.to_f / deployment['nodes'].length >= 1
end

def cleanup!(job = nil, deployment = nil)
  synchronize do
    if job.nil? && deployment.nil?
      @deployments.each(&:delete)
      @jobs.each(&:delete)
    else
      @deployments.delete(deployment) && deployment.delete unless deployment.nil?
      @jobs.delete(job) && job.delete unless job.nil?
    end
  end
end

def synchronize(&block)
  @mutex.synchronize(&block)
end

@GATEWAY = Net::SSH::Gateway.new("frontend.#{siteg5k}.grid5000.fr", config['username'])
@SSH = Net::SSH.start("frontend.#{siteg5k}.grid5000.fr", config['username'])

def ssh_exec!(ssh, command, res = {})
  res[:stdout] = '' if res[:stdout].nil?
  res[:stderr] = '' if res[:stderr].nil?
  res[:exit_code] = nil
  res[:exit_signal] = nil
  ssh.open_channel do |channel|
    channel.exec(command) do |_ch, success|
      abort "FAILED: couldn't execute command (ssh.channel.exec)" unless success
      channel.on_data do |_ch, data|
        res[:stdout] += data
      end

      channel.on_extended_data do |_ch, _type, data|
        res[:stderr] += data
      end

      channel.on_request('exit-status') do |_ch, data|
        res[:exit_code] = data.read_long
      end

      channel.on_request('exit-signal') do |_ch, data|
        res[:exit_signal] = data.read_long
      end
    end
  end
  ssh.loop
  res
end

def connect(_deployments, cmd)
  results = {}
  value = 'FAIL'
  @deployments.each do |deployment|
    deployment['nodes'].each do |host|
      print "\n\t*** #{host} ***\n\n"
      @GATEWAY.ssh(host, 'root', keys: [PRIVATE_KEY], auth_methods: ['publickey']) do |ssh|
        results = ssh_exec!(ssh, cmd)
        puts "#{results[:stdout]}\n\n"
      end
      puts " This command not run on this node\n\n" if results[:stdout].empty?
      @retval = 1 if results[:stdout].include?(value)
    end
  end
end

def kastat_info(_deployments)
  results = {}
  @deployments.each do |deployment|
    deployment['nodes'].each do |node|
      puts  node
      cmd = "kastat3 -b -x $(date --date='1 week ago' '+%Y:%m:%d:%H:%M:%S') -m #{node} -y $(date '+%Y:%m:%d:%H:%M:%S')"
      results = ssh_exec!(@SSH, cmd)
      puts " \n\n ** Since week, kadeploy failure rate on this node at this date(percentage) <=> [ #{results[:stdout]} ]"
    end
  end
end

Restfully::Session.new(base_uri: config['base_uri'], username: config['username'], password: config['password']) do |root, _session|
  job = job_manager.get_job(root, logger, options)
  if job.nil?
    @retval = 1
  else
    begin
      pp envg5k
      deployment = root.sites[:"#{siteg5k}"].deployments.submit({ nodes: job['assigned_nodes'], environment: 'wheezy-x64-min', key: File.read(PUBLIC_KEY) })
      logger.info " [#{siteg5k}] launching '#{envg5k}' on [#{job['assigned_nodes'].join(',')}]"

      if deployment.nil?
        logger.error "[#{siteg5k}] can not submit deployment "
        return false
      else

        deployment.reload
        synchronize { @deployments.push(deployment) }

        logger.info "[#{siteg5k}] Got the following deployment: #{deployment.inspect}"
        logger.info "[#{siteg5k}] Waiting for termination of deployment ##{deployment['uid']} in #{deployment.parent['uid']}..."
        begin
          Timeout.timeout(options[:'kadeploy3-timeout']) do
            while deployment.reload['status'] == 'processing'
              logger.info "[#{siteg5k}] Waiting deployment to finish on [ #{job['assigned_nodes'].join(',')} ]"
              sleep polling_frequency
            end
          end
        rescue Timeout::Error => e
          @retval = 1
          logger.error "Deployment Time Out. Received exception #{e.class.name} : #{e.message}"
          kastat_info(@deployments)
          exit @retval
        end

        if deployment_ok?(deployment)
          logger.info "[#{siteg5k}] Deployment is running: #{deployment.inspect} .. on [ #{job['assigned_nodes'].join(',')} ]\n "
          logger.info "Deployment finish with SUCCESS on node #{job['assigned_nodes'].join(',')}"
          time = Time.new
          @deployments.each do |d|
            d['nodes'].each do |host|
              print "\n\t*** #{host} ***\n\n"
              @GATEWAY.ssh(host, 'root', keys: [PRIVATE_KEY], auth_methods: ['publickey']) do |ssh|
                ssh_exec!(ssh, 'echo "deb http://apt.grid5000.fr/debian sid main" >> /etc/apt/sources.list')
                ssh_exec!(ssh, 'apt-get update')
                ssh_exec!(ssh, 'apt-get dist-upgrade -y --force-yes')
                ssh_exec!(ssh, 'apt-get install g5kchecks -y --force-yes')
                puts ssh_exec!(ssh, 'export PATH=/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin:/usr/local/games:/usr/games && g5k-checks -etestdisk -r -mjenkins')
                puts ssh_exec!(ssh, 'cat /var/lib/g5kchecks/*')
                ssh.sftp.download!("/tmp/#{host}_Jenkins_output.json", "#{time.strftime('%Y_%m_%d_%H_%M_%S')}_#{host}.json")
              end
            end
          end
        else
          @retval = 1
          synchronize { @deployments.delete(deployment) }
          logger.error "[#{siteg5k}] Deployment failed: #{deployment.inspect}"
          kastat_info(@deployments)
        end

      end
    ensure
      job_manager.delete_job(job)
    end
  end
end
exit @retval
