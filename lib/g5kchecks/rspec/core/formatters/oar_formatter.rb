# frozen_string_literal: true

module RSpec
  module Core
    module Formatters
      class OarFormatter
        RSpec::Core::Formatters.register self, :example_failed

        def initialize(output); end

        def example_failed(failedExampleNotification)
          file_name = failedExampleNotification.example.description.strip
          file_name = file_name.gsub(%r{/}, '\\').gsub(' ', '_')
          File.open(File.join(RSpec.configuration.output_dir, 'OAR_' + file_name), 'w') do |f|
            f.puts failedExampleNotification.example.execution_result.exception.to_json
          end
        end
      end
    end
  end
end
