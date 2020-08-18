# frozen_string_literal: true

require 'syslog'

module RSpec
  module Core
    module Formatters
      class SyslogFormatter
        RSpec::Core::Formatters.register self, :example_failed

        def initialize(output); end

        def log(priority, message)
          Syslog.open($PROGRAM_NAME, Syslog::LOG_PID | priority) { |s| s.warning message }
        end

        def example_failed(failedExampleNotification)
          array = failedExampleNotification.example.exception.message.split(', ')
          # faux positif (donnée présente dans l'api mais non présente dans ohai)
          if array[0] != ''
            log(Syslog::LOG_ERR, "ERROR #{failedExampleNotification.example.example_group.description} #{failedExampleNotification.description}  #{failedExampleNotification.exception.message}")
          else
            log(Syslog::LOG_INFO, "OK #{failedExampleNotification.example.example_group.description} #{failedExampleNotification.description}")
          end
        end

        def example_passed(_example)
          log(Syslog::LOG_INFO, "OK #{failedExampleNotification.example.example_group.description} #{failedExampleNotification.description}")
        end

        def example_pending(_example)
          log(Syslog::LOG_WARNING, "PENDING #{failedExampleNotification.example.example_group.description} #{failedExampleNotification.description}")
        end
      end
    end
  end
end
