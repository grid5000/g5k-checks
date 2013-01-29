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

      if conf[:testlist]
        conf[:testlist].each{|t|
          rspec_opts << File.dirname(__FILE__) + "/g5kchecks/spec/#{t}/#{t}_spec.rb"
        }
      else
        Dir.foreach(File.dirname(__FILE__) + '/g5kchecks/spec/') do |c|
          next if c == '.' or c == '..'
          rspec_opts << File.dirname(__FILE__) + "/g5kchecks/spec/#{c}/#{c}_spec.rb"
        end
      end

      if !conf[:api]
        require 'g5kchecks/rspec/core/formatters/syslog_formatter'
        require 'g5kchecks/rspec/core/formatters/oar_formatter'
        RSpec.configure do |c|
          c.add_formatter(:documentation)
          c.add_formatter(RSpec::Core::Formatters::OarFormatter)
          c.add_formatter(RSpec::Core::Formatters::SyslogFormatter)
        end
      else
        require 'g5kchecks/rspec/core/formatters/api_formatter'
        RSpec.configure do |c|
          c.add_formatter(RSpec::Core::Formatters::APIFormatter)
        end
      end

      if !File.directory?(conf[:checks_for_init_dir])
        Dir.mkdir(conf[:checks_for_init_dir], 0755)
      end

      RSpec.configure do |config|
        config.add_setting :node
        config.node = Grid5000::Node.new(conf[:api], "https://api.grid5000.fr/sid")
        config.add_setting :oar_dir
        config.oar_dir = conf[:checks_for_init_dir]
      end

      RSpec::Core::Runner::run(rspec_opts)
    end

  end
end


