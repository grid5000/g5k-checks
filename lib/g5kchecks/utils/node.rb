# frozen_string_literal: true

# retrieve node configuration (with Ohai) and the corresponding API
# characteristics.
require 'socket'
require 'rest-client'
require 'json'
require 'yaml'
require 'ohai'
require 'g5kchecks/utils/utils'

Ohai.config[:plugin_path] << File.expand_path(File.join(File.dirname(__FILE__), '/../ohai'))

# This is a monkey-patch of Ohai::DSL::Plugin to detect when a plugin fails.
# By default, Ohai only logs the exception
module Ohai
  module DSL
    class Plugin
      old_run = instance_method(:run)
      define_method(:run) do
        old_run.bind(self).call
      rescue Exception => e
        warn "ERROR: plugin #{name} returned an exception. Exiting."
        warn "#{e.inspect} #{e.backtrace.join("\n")}"
        exit!(1)
      end
    end
  end
end

module Grid5000
  class Node
    attr_reader :hostname
    attr_reader :node_uid, :cluster_uid, :site_uid, :grid_uid
    attr_reader :api, :node_path, :conf

    def initialize(conf)
      @conf = conf
      @hostname = Socket.gethostname
      @node_uid, @site_uid, @grid_uid, @ltd = hostname.split('.')
      @cluster_uid = @node_uid.split('-')[0]
      @ohai_description = nil
      @api_description = nil
      @max_retries = 2
    end

    def api_description
      return @api_description unless @api_description.nil?

      if @conf['mode'] == 'api'
        @api_description = JSON.parse '{}'
      elsif @conf['retrieve_from'] == 'rest'
        @branch = if conf['branch'].nil?
                    ''
                  else
                    '?branch=' + conf['branch']
                  end
        @node_path = [
          conf['retrieve_url'],
          'sites', site_uid,
          'clusters', cluster_uid,
          'nodes', node_uid
        ].join('/')
        begin
          @api_description = JSON.parse RestClient::Resource.new(@node_path + @branch, user: @conf['apiuser'], password: @conf['apipasswd'], headers: {
            accept: :json
          }).get
        rescue RestClient::ResourceNotFound
          if !@conf['fallback_branch'].nil?
            begin
              @api_description = JSON.parse RestClient::Resource.new(@node_path + '?branch=' + @conf['fallback_branch'], user: @conf['apiuser'], password: @conf['apipasswd'], headers: {
                accept: :json
              }).get
            rescue RestClient::ResourceNotFound
              raise "Node not found with url #{@node_path + @branch} and #{@node_path + '?branch=' + @conf['fallback_branch']}"
            rescue RestClient::ServiceUnavailable => e
              @retries ||= 0
              if @retries < @max_retries
                @retries += 1
                sleep 10
                retry
              else
                raise e
              end
            end
          else
            raise "Node not find with url #{@node_path + @branch}"
          end
        rescue StandardError => e
          @retries ||= 0
          if @retries < @max_retries
            @retries += 1
            sleep 10
            retry
          else
            raise e
          end
        end
      elsif @conf['retrieve_from'] == 'file'
        @node_path = File.join(@conf['retrieve_dir'], @hostname + '.json')
        @api_description = JSON.parse(File.read(@node_path))
      end
      @api_description
    end

    def get_wanted_mountpoint
      return @conf['mountpoint'] unless @conf['mountpoint'].nil?

      []
    end

    def ohai_description
      unless @ohai_description
        @ohai_description = Ohai::System.new
        # Disable plugins that always fail to run and are not needed by G5K-checks
        Ohai.config.disabled_plugins = %i[Eucalyptus Virtualbox Chef SSHHostKey]
        if Utils.dmi_supported?
          Ohai.config.disabled_plugins.push(:DeviceTree)
        else
          Ohai.config.disabled_plugins.push(:DMI, :DMIExtend, :ShardSeed)
        end

        if @conf['debug'] == true
          Ohai::Log.init(STDOUT)
          Ohai::Log.level = :debug
        end
        @ohai_description.all_plugins
      end
      @ohai_description
    end
  end
end
