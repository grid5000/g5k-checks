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
      ipmitool_cmd = 'ipmitool -I open bmc info'
      ipmitool_lines = ''
      ipmitool_status = 1

      begin
        Open3.popen3(ipmitool_cmd) do |_stdin, stdout, _stderr, wait_thr|
          # pid = wait_thr.pid # pid of the started process.
          ipmitool_status = wait_thr.value # Process::Status object returned.
          ipmitool_lines = stdout.readlines
        end

        if ipmitool_status == 0
          ipmitool_lines.each do |line|
            return Regexp.last_match(1) if line =~ /^Firmware Revision\s+\:\s+(.+)$/
          end
        end
      rescue Errno::ENOENT
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
