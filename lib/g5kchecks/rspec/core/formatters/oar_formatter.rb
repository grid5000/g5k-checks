# coding: utf-8

module RSpec
  module Core
    module Formatters
      class OarFormatter

        RSpec::Core::Formatters.register self, :example_failed

        def initialize(output)
        end

        def example_failed(failedExampleNotification)
          array = failedExampleNotification.exception.message.split(', ')
          # pas super beau, pour distinguer plusieurs composants
          # typiquement pour disk et network
          if array[0] =~ /mount/
            file_name = array[0]
	  elsif array[-2] =~ /\d{1,2}/
            file_name = failedExampleNotification.example.full_description.gsub(" ","_") + "_" + array[-2]
          elsif array[-2] =~ /sd./
            file_name = failedExampleNotification.example.full_description.gsub(" ","_") + "_" + array[-2]
	  else
            file_name = failedExampleNotification.example.full_description.gsub(" ","_")
          end
	  file_name = file_name.gsub(/\//,'\\').gsub(" ","_")
          File.open(File.join(RSpec.configuration.output_dir, "OAR_"+file_name), 'w') do |f|
            f.puts failedExampleNotification.example.execution_result.exception.to_json
          end
        end
      end
    end
  end
end
