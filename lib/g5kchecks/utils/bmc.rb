# frozen_string_literal: true

require 'json'
require 'yaml'

require 'g5kchecks/utils/utils'

module Grid5000
  # Class helping to collect BMC version
  module BMC
    include Utils::Mixin
    def fetch_info
      bmc_vendor_tool = local_api_description['management_tools']['bmc_vendor_tool'] rescue 'ipmitool'

      version = case bmc_vendor_tool
                when 'ipmitool'
                  fetch_ipmitool
                when 'racadm'
                  fetch_racadm || fetch_ipmitool
                when 'none'
                  nil
                else
                  raise "Unknown BMC vendor tool #{bmc_vendor_tool}!"
                end

      version ? { 'version' => version } : { 'version' => 'unknown' }
    end

    def fetch_racadm
      begin
        shell_out = shell_out('racadm get iDRAC.Info.version')
        racadm_lines = shell_out.stdout.split
        racadm_lines[1].chomp.split('=')[1] if shell_out.exitstatus == 0
      rescue StandardError
        nil
      end
    end

    def fetch_ipmitool
      begin
        shell_out = ipmitool_shell_out('-I open bmc info')

        if shell_out.exitstatus == 0
          shell_out.stdout.each_line do |line|
            return Regexp.last_match(1) if line =~ /^Firmware Revision\s+\:\s+(.+)$/
          end
        end
      rescue StandardError
        nil
      end
    end
  end
end

