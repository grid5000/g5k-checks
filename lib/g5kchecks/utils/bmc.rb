require 'open3'
require 'json'
require 'yaml'

module Grid5000

  # Class helping to collect Dell BMC (iDrac) version
  class DellBMC

    def fetch_info()
      begin
        cmd = 'sudo racadm get iDRAC.Info.version'
        lines = ''
        exit_status = 1
        Open3.popen3(cmd) { |stdin, stdout, stderr, wait_thr|
          pid = wait_thr.pid # pid of the started process.
          exit_status = wait_thr.value # Process::Status object returned.
          lines = stdout.readlines
        }
        if exit_status == 0
          result = { 'version' => lines[1].chomp.split('=')[1] }
          result
	else
	  { 'version' => 'unknown' }
        end
      rescue Errno::ENOENT
        raise 'racadm not found'
      end
    end

    def get_json()
      fetch_info().to_json()
    end
  end
end

# To test the above class in command line
if $PROGRAM_NAME == __FILE__
  bmc_info = Grid5000::DellBMC.new
  puts bmc_info.get_json()
end
