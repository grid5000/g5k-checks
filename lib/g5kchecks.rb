#!/usr/bin/ruby -w

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

      if conf[:testlist] and conf[:testlist][0] != "all"
        conf[:testlist].each{|t|
          rspec_opts << File.dirname(__FILE__) + "/g5kchecks/spec/#{t}/#{t}_spec.rb"
        }
      else
        Dir.foreach(File.dirname(__FILE__) + '/g5kchecks/spec/') do |c|
          next if c == '.' or c == '..'
          rspec_opts << File.dirname(__FILE__) + "/g5kchecks/spec/#{c}/#{c}_spec.rb"
        end
      end

      if conf[:removetestlist]
        conf[:removetestlist].each{|t|
          test = File.dirname(__FILE__) + "/g5kchecks/spec/#{t}/#{t}_spec.rb"
          i = rspec_opts.find_index(test)
          rspec_opts.delete_at(i.to_i)
        }
      end

      if conf[:mode] == "oar_checks"
        require 'g5kchecks/rspec/core/formatters/syslog_formatter'
        require 'g5kchecks/rspec/core/formatters/oar_formatter'
        RSpec.configure do |c|
          c.add_formatter(RSpec::Core::Formatters::OarFormatter)
          c.add_formatter(RSpec::Core::Formatters::SyslogFormatter)
        end
      elsif conf[:mode] == "api"
        require 'g5kchecks/rspec/core/formatters/api_formatter'
        RSpec.configure do |c|
          c.add_formatter(RSpec::Core::Formatters::APIFormatter)
        end
      elsif conf[:mode] == "jenkins"
        require 'g5kchecks/rspec/core/formatters/jenkins_formatter'
        RSpec.configure do |c|
          c.add_formatter(RSpec::Core::Formatters::JenkinsFormatter)
        end
      end

      if !File.directory?(conf[:checks_for_init_dir])
        Dir.mkdir(conf[:checks_for_init_dir], 0755)
      else
        Dir.foreach(conf[:checks_for_init_dir]) {|f|
          fn = File.join(conf[:checks_for_init_dir], f);
          File.delete(fn) if f != '.' && f != '..'
        }
      end

      RSpec.configure do |config|
        config.add_setting :node
        config.node = Grid5000::Node.new(conf[:mode], "https://api.grid5000.fr/sid")
        config.add_setting :oar_dir
        config.oar_dir = conf[:checks_for_init_dir]
      end

      RSpec::Core::Runner::run(rspec_opts)
    end

  end
end


