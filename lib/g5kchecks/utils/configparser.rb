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
        config = YAML.load_file(@path)
      rescue ArgumentError
        raise ArgumentError.new("Invalid YAML file '#{@path}'")
      rescue Errno::ENOENT
        raise ArgumentError.new("File not found '#{@path}'")
      end
      @hash[:checks_for_init_dir] = config["checks_for_init_dir"]
      @hash[:testlist] = config["checks_for_oar"].split(',') if config["checks_for_oar"]
      @hash[:removetestlist] = config["removetestlist"].split(',') if config["removetestlist"]
      @hash[:urlapi] = config["urlapi"] if config["urlapi"]
      @hash[:branch] = config["branch"] if config["branch"]
      @hash[:mountpoint] = config["mountpoint"] if config["mountpoint"]
      return @hash
    end
  end
end
