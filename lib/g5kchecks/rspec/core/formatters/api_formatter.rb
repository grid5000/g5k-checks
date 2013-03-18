require 'rspec/core/formatters/base_text_formatter'
require 'g5kchecks/utils/utils'
require 'yaml'

module RSpec
  module Core
    module Formatters
      class APIFormatter < BaseTextFormatter

        attr_reader :output_hash, :yaml_hash

        def initialize(output)
          super
          @output_hash = {}
          @yaml_hash = Hash.new
        end

        def message(message)
          (@output_hash[:messages] ||= []) << message
        end

        def stop
          super
          @output_hash[:examples] = examples.each do |example|
            if e=example.exception
              array = e.message.split(', ')
              if array.size > 1
                value = array.delete_at(0)
                next if value == ""
                # on enlève la valeur de l'api qui doit être nulle
                array.delete_at(0)
                add_to_yaml_hash(array,value,@yaml_hash)
              end
            end
          end
        end

        def close
          File.open(File.join("/tmp/",RSpec.configuration.node.hostname + ".yaml"), 'w' ) { |f|
            f.puts @yaml_hash.to_yaml
          }
          File.open(File.join("/tmp/",RSpec.configuration.node.hostname + ".json"), 'w' ) { |f|
            f.puts @yaml_hash.to_json
          }
        end

        def add_to_yaml_hash(array, value, hash)
          if array.size == 1
            # puts array[0]
            hash[array[0]] = Utils.string_to_object(value)
            return hash
          else
            tmp = Utils.string_to_object(array.delete_at(0))
            if hash[tmp]
              add_to_yaml_hash(array,value, hash[tmp])
            else
              hash[tmp] = add_to_yaml_hash(array,value, Hash.new)
              return hash
            end
          end
        end

      end
    end
  end
end
