
module RSpec
  module Core
    module Formatters

      class VerboseFormatter

        RSpec::Core::Formatters.register self, :example_group_started, :example_group_finished, :example_passed, :example_pending, :example_failed

        def initialize(output)
          @group_level = 0
        end

        def example_group_started(groupNotification)
          #super(example_group)

          puts if @group_level == 0
          puts "#{current_indentation}#{groupNotification.group.description.strip}"

          @group_level += 1
        end

        def example_group_finished(groupNotification)
          @group_level -= 1
        end

        def example_passed(exampleNotification)
          if respond_to? :success_color
            puts success_color("\e[32m  OK " + exampleNotification.example.description.strip + "\e[0m")
          else
            puts "\e[32m  OK " + exampleNotification.example.description.strip + "\e[0m"
          end
        end

        def example_pending(example)
          puts pending_color(example.description.strip)
        end

        def example_failed(failedExampleNotification)
          puts failure_output(failedExampleNotification.example, failedExampleNotification.example.exception)
        end

        def failure_output(example, exception)
          if respond_to? :failure_color
            failure_color("\e[31mKO #{exception.message} (FAILED - #{next_failure_index})\e[0m")
          else
            "\e[31mKO #{exception.message} (FAILED - #{next_failure_index})\e[0m"
          end
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
