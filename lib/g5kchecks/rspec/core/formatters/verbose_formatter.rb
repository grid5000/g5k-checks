# frozen_string_literal: true

module RSpec
  module Core
    module Formatters
      class VerboseFormatter
        RSpec::Core::Formatters.register self, :example_group_started, :example_group_finished, :example_passed, :example_failed

        def initialize(_output)
          @group_level = 0
        end

        def example_group_started(groupNotification)
          puts if @group_level == 0
          puts "#{current_indentation}#{groupNotification.group.description.strip}"

          @group_level += 1
        end

        def example_group_finished(_groupNotification)
          @group_level -= 1
        end

        def example_passed(exampleNotification)
          print_success(exampleNotification.example.description.strip)
        end

        def example_failed(failedExampleNotification)
          print_error("#{failedExampleNotification.example.full_description.strip}. #{failedExampleNotification.example.execution_result.exception} (FAILED - #{next_failure_index})")
        end

        def print_success(msg)
          if $stdout.isatty
            puts "\e[32m  OK " + msg + "\e[0m"
          else
            puts ' OK ' + msg
          end
        end

        def print_error(msg)
          if $stdout.isatty
            puts "\e[31m  KO " + msg + "\e[0m"
          else
            puts ' KO ' + msg
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
