# coding: utf-8

require 'g5kchecks/utils/utils'
require 'yaml'

module RSpec
  module Core
    module Formatters
      class APIFormatter

        RSpec::Core::Formatters.register self, :close

        attr_reader :output_hash, :yaml_hash

        def initialize(output)
        end

        def close(nullNotification)
          #Writing node api description files at and of run
          File.open(File.join("/tmp/", RSpec.configuration.node.hostname + ".yaml"), 'w' ) { |f|
            f.puts RSpec.configuration.api_yaml.to_yaml
          }
          File.open(File.join("/tmp/",RSpec.configuration.node.hostname + ".json"), 'w' ) { |f|
            f.puts RSpec.configuration.api_yaml.to_json
          }
        end
      end
    end
  end
end
