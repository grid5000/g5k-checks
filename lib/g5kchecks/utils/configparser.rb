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
        raise ArgumentError.new("Invalid YAML file '#{@path}'")
      rescue Errno::ENOENT
        raise ArgumentError.new("File not found '#{@path}'")
      end
      return @hash
    end
  end
end
