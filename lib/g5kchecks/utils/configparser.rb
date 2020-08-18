# frozen_string_literal: true

# A very tiny configuration parser
require 'yaml'

module G5kChecks
  class ConfigParser
    def initialize(configpath)
      # The config path
      @path = configpath
      # Hash to be return after the file parsing
      @hash = {}
    end

    def parse
      begin
        @hash = YAML.load_file(@path)
      rescue ArgumentError
        raise ArgumentError, "Invalid YAML file '#{@path}'"
      rescue Errno::ENOENT
        raise ArgumentError, "File not found '#{@path}'"
      end
      @hash
    end
  end
end
