require 'open3'
require 'json'
require 'yaml'

module Grid5000

  # Class helping to collect BMC version
  class BMC
    def fetch_info()
      racadm_version = fetch_racadm
      if racadm_version
        version = racadm_version
      else
        version = fetch_ipmitool
      end

      version ? { 'version' => version } : { 'version' => 'unknown' }
    end

    def fetch_racadm
      racadm_cmd = 'racadm get iDRAC.Info.version'
      racadm_lines = ''
      racadm_status = 1

      begin
        Open3.popen3(racadm_cmd) { |stdin, stdout, stderr, wait_thr|
          pid = wait_thr.pid # pid of the started process.
          racadm_status = wait_thr.value # Process::Status object returned.
          racadm_lines = stdout.readlines
        }
        if racadm_status == 0
          return racadm_lines[1].chomp.split('=')[1]
        else
          return nil
        end
      rescue Errno::ENOENT
        return nil
      end
    end

    def fetch_ipmitool
      ipmitool_cmd = 'ipmitool -I open bmc info'
      ipmitool_lines = ''
      ipmitool_status = 1

      begin
        Open3.popen3(ipmitool_cmd) { |stdin, stdout, stderr, wait_thr|
          pid = wait_thr.pid # pid of the started process.
          ipmitool_status = wait_thr.value # Process::Status object returned.
          ipmitool_lines = stdout.readlines
        }

        if ipmitool_status == 0
          ipmitool_lines.each do |line|
            if line =~ /^Firmware Revision\s+\:\s+(.+)$/
              return $1
            end
          end
        else
          return nil
        end
      rescue Errno::ENOENT
        return nil
      end
    end

    def get_json()
      fetch_info().to_json()
    end
  end
end

# To test the above class in command line
if $PROGRAM_NAME == __FILE__
  bmc_info = Grid5000::BMC.new
  puts bmc_info.get_json()
end
