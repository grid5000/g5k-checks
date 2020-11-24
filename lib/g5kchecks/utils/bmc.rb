# frozen_string_literal: true

require 'open3'
require 'json'
require 'yaml'

module Grid5000
  # Class helping to collect BMC version
  class BMC
    def fetch_info
      racadm_version = fetch_racadm
      version = racadm_version || fetch_ipmitool

      version ? { 'version' => version } : { 'version' => 'unknown' }
    end

    def fetch_racadm
      racadm_cmd = 'racadm get iDRAC.Info.version'
      racadm_lines = ''
      racadm_status = 1

      begin
        Open3.popen3(racadm_cmd) do |_stdin, stdout, _stderr, wait_thr|
          # pid = wait_thr.pid # pid of the started process.
          racadm_status = wait_thr.value # Process::Status object returned.
          racadm_lines = stdout.readlines
        end
        racadm_lines[1].chomp.split('=')[1] if racadm_status == 0
      rescue Errno::ENOENT
        nil
      end
    end

    def fetch_ipmitool
      begin
        shell_out = Utils.shell_out('/usr/bin/ipmitool -I open bmc info', timeout: 120)

        if shell_out.exitstatus == 0
          shell_out.stdout.each_line do |line|
            return Regexp.last_match(1) if line =~ /^Firmware Revision\s+\:\s+(.+)$/
          end
        end
      rescue Errno::ENOENT
        nil
      end

      nil
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
