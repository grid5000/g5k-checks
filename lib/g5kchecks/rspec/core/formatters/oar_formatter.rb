require 'rspec/core/formatters/base_text_formatter'

module RSpec
  module Core
    module Formatters
      class OarFormatter < BaseTextFormatter

        def initialize(oardir)
          super
        end

        def example_failed(example)
          # bypass si l'api est rempli et que g5kcheks ne trouve
          # pas la valeur
          if example.exception.message.split(', ')[-2] != nil
            # pas super beau, pour distinguer plusieurs composants
            # typiquement pour disk et network
            if example.exception.message.split(', ')[-2] =~ /\d{1,2}/
              file_name = example.full_description.gsub(" ","_") + "_" + example.exception.message.split(', ')[-2]
            else
              file_name = example.full_description.gsub(" ","_")
            end
            File.open(RSpec.configuration.oar_dir + file_name, 'w') do |f|
              f.puts example.execution_result.to_yaml
            end
          end
        end

        def example_passed(example)
        end

        def example_pending(example)
        end
      end
    end
  end
end
