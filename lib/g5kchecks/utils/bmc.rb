# frozen_string_literal: true

require 'json'
require 'yaml'
require 'socket'
require 'g5kchecks/utils/utils'

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

    def get_idrac_errors
      # List of ignored error taken from jenkins openmanage test
      log_to_ignore = [
        [ /^(econome|grcinq|dahu|grvingt|paranoia)-/, /^UNKNOWN: Storage Error! No controllers found/ ], # storage controllers are not detected on C6220 and C6420
        [ /^(nova|grcinq)-/, /^CRITICAL: Voltage sensor .* is \[N\/A\]$/ ],
        [ /^(taurus|orion)-/, /^CRITICAL: Power Supply 1 \[AC\]: Presence Detected, AC Lost$/ ],
        [ /.*/, /^WARNING: Controller 0 \[PERC .*\]: Firmware '.*' is out of date$/ ],
        [ /.*/, /^UNKNOWN: / ], # Ignore all UNKNOWN errors
        [ /.*/, /^OK - / ], # Ignore OK lines
        [/^(orion|taurus)-/, /^WARNING: Physical Disk .* is Online, Failure Predicted$/], # old cluster
        [/^taurus-(12|10)/, /^WARNING: Chassis intrusion 0 detected: Chassis is open$/] # The chassis is closed, the sensor is broken
      ]
      hostname = Socket.gethostname
      check_openmanage = File.expand_path('/bin/sh ../data/check_openmanage', File.dirname(__FILE__))
      check_openmanage_stdout = Utils.shell_out("#{check_openmanage} -s").stdout
      if not fetch_racadm.nil?
        check_openmanage_stdout.split(/(?:\n|<br\/>)/).reject { |l| not log_to_ignore.select { |e| e[0] =~ hostname and e[1] =~ l }.empty? }
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
