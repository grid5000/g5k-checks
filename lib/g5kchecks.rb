#!/usr/bin/ruby
# frozen_string_literal: true

require 'rspec'

require 'g5kchecks/utils/node'
require 'g5kchecks/utils/utils'

module G5kChecks
  class G5kChecks::G5kChecks
    def initialize
      super
      trap('TERM') do
        $stderr.puts 'SIGTERM received, stopping'
        exit!(1)
      end
      trap('INT') do
        $stderr.puts 'SIGINT received, stopping'
        exit!(2)
      end
    end

    def run(conf)
      rspec_opts = []

      rspec_opts << Dir.glob(File.dirname(__FILE__) + '/g5kchecks/spec/**/*_spec.rb')

      if conf['verbose']
        require 'g5kchecks/rspec/core/formatters/verbose_formatter'
        RSpec.configure do |c|
          c.add_formatter(RSpec::Core::Formatters::VerboseFormatter)
        end
      end

      if conf['mode'] == 'oar_checks'
        require 'g5kchecks/rspec/core/formatters/syslog_formatter'
        require 'g5kchecks/rspec/core/formatters/oar_formatter'
        RSpec.configure do |c|
          c.add_formatter(RSpec::Core::Formatters::OarFormatter)
          c.add_formatter(RSpec::Core::Formatters::SyslogFormatter)
        end
      elsif conf['mode'] == 'jenkins'
        require 'g5kchecks/rspec/core/formatters/jenkins_formatter'
        RSpec.configure do |c|
          c.add_formatter(RSpec::Core::Formatters::JenkinsFormatter)
        end
      end

      if !File.directory?(conf['output_dir'])
        Dir.mkdir(conf['output_dir'], 0o755)
      else
        Dir.foreach(conf['output_dir']) do |f|
          fn = File.join(conf['output_dir'], f)
          File.delete(fn) if f != '.' && f != '..'
        end
      end

      RSpec.configure do |config|
        config.deprecation_stream = '/dev/null'
        config.add_setting :node
        config.node = Grid5000::Node.new(conf)
        if conf['mode'] == 'api'
          config.add_setting :api_yaml
          config.api_yaml = ({})
        end
        config.add_setting :output_dir
        config.output_dir = conf['output_dir']
      end

      if conf['mode'] != 'api'
        # Waiting for kadeploy to end its deployment before starting the tests
        hostname = Socket.gethostname
        state = get_kadeploy_state(hostname)
        wait_states = %w[deploying rebooting powering]
        success_states = %w[deployed rebooted powered]
        failure_states = %w[deploy_failed reboot_failed power_failed aborted]
        now = Time.now.to_i
        wait_timeout = 300
        unknown_timeout = 45
        while true
          if success_states.include?(state)
            break
          end
          if failure_states.include?(state)
            puts "Exiting with error because of kadeploy deployment state=#{state}"
            exit 1
          end
          if wait_states.include?(state)
            if Time.now.to_i > now + wait_timeout
              # The state can be stuck in "deploying" state if the server crashed, see bug 12535
              puts "Exiting with error because of timeout: deployment has stayed too long in state=#{state} (did the kadeploy server crash?)"
              exit 1
            else
              puts "Waiting for kadeploy to end its deployment (state=#{state})"
            end
          else
            # Unknown state: wait a bit, but not too long
            if Time.now.to_i > now + unknown_timeout
              puts "Exiting with error because of unknown state: deployment is in state=#{state}"
              exit 1
            else
              puts "Kadeploy deployment is in unknown state=#{state}, waiting a bit just in case"
            end
          end
          sleep 5
          state = get_kadeploy_state(hostname)
        end
      end

      res = RSpec::Core::Runner.run(rspec_opts)

      if conf['mode'] == 'api'
        # Finally writes /tmp/hostnmame.{yaml,json} if in API mode
        Utils.write_api_files
      end

      exit res
    end

    private

    def get_kadeploy_state(hostname)
      _node_uid, site_uid, _grid_uid, _ltd = hostname.split('.')
      json_node = Utils.api_call(RSpec.configuration.node.conf['retrieve_url'] + "/sites/#{site_uid}/internal/kadeployapi/nodes/#{hostname}")
      json_node['state']
    end
  end
end
