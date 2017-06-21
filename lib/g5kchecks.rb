#!/usr/bin/ruby

require 'rspec'

require 'g5kchecks/utils/node'
require 'g5kchecks/utils/utils'

module G5kChecks

  class G5kChecks::G5kChecks

    def initialize
      super
      trap("TERM") do
        RefAPIHelper::G5kRefAPIHelperNode.fatal!("SIGTERM received, stopping", 1)
      end
      trap("INT") do
        RefAPIHelper::G5kRefAPIHelperNode.fatal!("SIGINT received, stopping", 2)
      end
    end

    def run(conf)
      rspec_opts = []

      rspec_opts << Dir.glob(File.dirname(__FILE__) + "/g5kchecks/spec/**/*_spec.rb")

      if conf["verbose"] 
        require 'g5kchecks/rspec/core/formatters/verbose_formatter'
        RSpec.configure do |c|
          c.add_formatter(RSpec::Core::Formatters::VerboseFormatter)
        end
      end

      if conf["mode"] == "oar_checks"
        require 'g5kchecks/rspec/core/formatters/syslog_formatter'
        require 'g5kchecks/rspec/core/formatters/oar_formatter'
        RSpec.configure do |c|
          c.add_formatter(RSpec::Core::Formatters::OarFormatter)
          c.add_formatter(RSpec::Core::Formatters::SyslogFormatter)
        end
      elsif conf["mode"] == "jenkins"
        require 'g5kchecks/rspec/core/formatters/jenkins_formatter'
        RSpec.configure do |c|
          c.add_formatter(RSpec::Core::Formatters::JenkinsFormatter)
        end
      end

      if !File.directory?(conf["output_dir"])
        Dir.mkdir(conf["output_dir"], 0755)
      else
        Dir.foreach(conf["output_dir"]) {|f|
          fn = File.join(conf["output_dir"], f);
          File.delete(fn) if f != '.' && f != '..'
        }
      end

      RSpec.configure do |config|
        config.deprecation_stream = "/dev/null"
        config.add_setting :node
        config.node = Grid5000::Node.new(conf)
        if conf["mode"] == "api"
          config.add_setting :api_yaml
          config.api_yaml = Hash.new
        end
        config.add_setting :output_dir
        config.output_dir = conf["output_dir"]
      end

      res = RSpec::Core::Runner::run(rspec_opts)

      if conf["mode"] == "api"
        #Finally writes /tmp/hostnmame.{yaml,json} if in API mode
        Utils.write_api_files
      end

      exit res
    end
  end
end
