# frozen_string_literal: true

require 'json'
require 'yaml'

module Grid5000
  # Class helping to collect BMC version
  class BMC
    def fetch_info(chassis)
      version = fetch_racadm || fetch_ipmitool(chassis)

      version ? { 'version' => version } : { 'version' => 'unknown' }
    end

    def fetch_racadm
      begin
        shell_out = Utils.shell_out('racadm get iDRAC.Info.version')
        racadm_lines = shell_out.stdout.split
        racadm_lines[1].chomp.split('=')[1] if shell_out.exitstatus == 0
      rescue StandardError
        nil
      end
    end

    def fetch_ipmitool(chassis)
      begin
        shell_out = Utils.ipmitool_shell_out('-I open bmc info', chassis)

        if shell_out.exitstatus == 0
          shell_out.stdout.each_line do |line|
            return Regexp.last_match(1) if line =~ /^Firmware Revision\s+\:\s+(.+)$/
          end
        end
      rescue StandardError
        nil
      end
    end

    def get_json
      fetch_info.to_json
    end
  end
end

# To test the above class in command line
if $PROGRAM_NAME == __FILE__
  bmc_info = Grid5000::BMC.new
  puts bmc_info.get_json
end
