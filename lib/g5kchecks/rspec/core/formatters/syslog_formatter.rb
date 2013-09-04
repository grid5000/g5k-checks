require 'syslog'
require 'rspec/core/formatters/base_text_formatter'

module RSpec
  module Core
    module Formatters
      class SyslogFormatter < BaseTextFormatter

        def log(priority,message)
          Syslog.open($0, Syslog::LOG_PID | priority) { |s| s.warning message }
        end

        def example_failed(example)
          array = example.exception.message.split(', ')
          # faux positif (donnée présente dans l'api mais non présente dans ohai)
          if array[0] != ""
            log(Syslog::LOG_ERR, "ERROR #{example_group.description} #{example.description}  #{example.exception.message}")
          else
            log(Syslog::LOG_INFO, "OK #{example_group.description} #{example.description}")
          end
        end

        def example_passed(example)
          log(Syslog::LOG_INFO, "OK #{example_group.description} #{example.description}")
        end

        def example_pending(example)
          log(Syslog::LOG_WARNING, "PENDING #{example_group.description} #{example.description}")
        end
      end
    end
  end
end
