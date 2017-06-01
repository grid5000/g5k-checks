
require 'g5kchecks/utils/utils'
require 'yaml'

module RSpec
  module Core
    module Formatters
      class JenkinsFormatter

        RSpec::Core::Formatters.register self, :stop, :close

        attr_reader :output_hash, :yaml_hash

        def initialize(output)
          @output_hash = {}
          @yaml_hash = Hash.new
        end

        def message(message)
          (@output_hash[:messages] ||= []) << message
        end

        def stop(examplesNotification)
          @output_hash[:examples] = examplesNotification.examples.each do |example|
            if e=example.exception
              # bypass si l'api est rempli et que g5kcheks ne trouve
              # pas la valeur
              array = example.exception.message.split(', ')
              if array[0] != ""
                # pas super beau, pour distinguer plusieurs composants
                # typiquement pour disk et network
                if array[-2] =~ /\d{1,2}/
                  desc = example.full_description.gsub(" ","_") + "_" + array[-2]
                else
                  desc = example.full_description.gsub(" ","_")
                end
                @yaml_hash[desc] = {}
                @yaml_hash[desc][:attribut] = example.exception.message.split(', ')[-2,2]
                @yaml_hash[desc][:was] = example.exception.message.split(', ')[1]
                @yaml_hash[desc][:should_be] = example.exception.message.split(', ')[0]
              end
            end
          end
        end

        def close(nullNotification)
          File.open(File.join("/tmp/",RSpec.configuration.node.hostname + "_Jenkins_output.json"), 'w' ) { |f|
            f.puts @yaml_hash.to_json
          }
        end
      end
    end
  end
end
