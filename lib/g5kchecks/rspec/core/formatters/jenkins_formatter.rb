# frozen_string_literal: true

require 'g5kchecks/utils/utils'
require 'yaml'

module RSpec
  module Core
    module Formatters
      class JenkinsFormatter
        RSpec::Core::Formatters.register self, :stop, :close

        attr_reader :output_hash, :yaml_hash

        def initialize(_output)
          @output_hash = {}
          @yaml_hash = {}
        end

        def message(message)
          (@output_hash[:messages] ||= []) << message
        end

        def stop(examplesNotification)
          @output_hash[:examples] = examplesNotification.examples.each do |example|
            next unless example.exception

            # bypass si l'api est rempli et que g5kcheks ne trouve
            # pas la valeur
            array = example.exception.message.split(', ')
            next unless array[0] != ''

            # pas super beau, pour distinguer plusieurs composants
            # typiquement pour disk et network
            desc = if /\d{1,2}/.match?(array[-2])
                     example.full_description.tr(' ', '_') + '_' + array[-2]
                   else
                     example.full_description.tr(' ', '_')
                   end
            @yaml_hash[desc] = {}
            @yaml_hash[desc][:attribut] = example.exception.message.split(', ')[-2, 2]
            @yaml_hash[desc][:was] = example.exception.message.split(', ')[1]
            @yaml_hash[desc][:should_be] = example.exception.message.split(', ')[0]
          end
        end

        def close(_nullNotification)
          File.open(File.join('/tmp/', RSpec.configuration.node.hostname + '_Jenkins_output.json'), 'w') do |f|
            f.puts @yaml_hash.to_json
          end
        end
      end
    end
  end
end
