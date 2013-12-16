require 'rspec/core/formatters/base_text_formatter'
module RSpec
  module Core
    module Formatters

      class VerboseFormatter < BaseTextFormatter

        def initialize(output)
          super(output)
          @group_level = 0
        end

        def example_group_started(example_group)
          super(example_group)

          puts if @group_level == 0
          puts "#{current_indentation}#{example_group.description.strip}"

          @group_level += 1
        end

        def example_group_finished(example_group)
          @group_level -= 1
        end

        def example_passed(example)
          super(example)
          puts success_color("\e[32m  OK " + example.description.strip + "\e[0m")
        end

        def example_pending(example)
          super(example)
          puts pending_color(example.description.strip)
        end

        def example_failed(example)
          super(example)
          puts failure_output(example, example.execution_result[:exception])
        end

        def failure_output(example, exception)
          failure_color("\e[31mKO #{example.exception.message} (FAILED - #{next_failure_index})\e[0m")
        end

        def current_indentation
          '  ' * @group_level
        end

        def next_failure_index
          @next_failure_index ||= 0
          @next_failure_index += 1
        end

        def start_dump
          output.puts
        end

      end

    end
  end
end
