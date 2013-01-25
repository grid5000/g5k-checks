#!/usr/bin/ruby -w

require 'rspec'

require 'g5kchecks/utils/node'

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

    def run(testlist,api)
      rspec_opts = []

      if testlist
        testlist.each{|t|
          rspec_opts << File.dirname(__FILE__) + "/g5kchecks/spec/#{t}/#{t}_spec.rb"
        }
      else
        Dir.foreach(File.dirname(__FILE__) + '/g5kchecks/spec/') do |c|
          next if c == '.' or c == '..'
          rspec_opts << File.dirname(__FILE__) + "/g5kchecks/spec/#{c}/#{c}_spec.rb"
        end
      end

      if !api
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

      RSpec.configure do |config|
        config.add_setting :node
        config.node = Grid5000::Node.new(api, "https://api.grid5000.fr/sid")
      end

      RSpec::Core::Runner::run(rspec_opts)
    end

  end
end


