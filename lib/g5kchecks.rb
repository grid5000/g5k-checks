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

      if conf["enabletestlist"] and conf["enabletestlist"][0] != "all"
        conf["enabletestlist"].each{|t|
          rspec_opts << File.dirname(__FILE__) + "/g5kchecks/spec/#{t}/#{t}_spec.rb"
        }
      else
        Dir.foreach(File.dirname(__FILE__) + '/g5kchecks/spec/') do |c|
          next if c == '.' or c == '..'
          rspec_opts << File.dirname(__FILE__) + "/g5kchecks/spec/#{c}/#{c}_spec.rb"
        end
      end

      if conf["removetestlist"]
        conf["removetestlist"].each{|t|
          test = File.dirname(__FILE__) + "/g5kchecks/spec/#{t}/#{t}_spec.rb"
          i = rspec_opts.find_index(test)
          rspec_opts.delete_at(i.to_i) if i
        }
      end

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
      elsif conf["mode"] == "api"
        require 'g5kchecks/rspec/core/formatters/api_formatter'
        RSpec.configure do |c|
          c.add_formatter(RSpec::Core::Formatters::APIFormatter)
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
        config.add_setting :output_dir
        config.output_dir = conf["output_dir"]
      end

      RSpec::Core::Runner::run(rspec_opts)
    end

  end
end


