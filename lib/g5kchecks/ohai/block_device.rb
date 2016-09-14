# -*- coding: utf-8 -*-
provides "block_device/improve"
require_plugin("block_device")

require 'open3'

# Execute an external program
def execute2(cmd)
  stdout, stderr, status = Open3.capture3(cmd)
  
  raise "#{cmd}: #{status.exitstatus}" unless status.success?
  
  stdout = stdout.split("\n")
  stdout = (stdout.size == 1 ? stdout[0] : stdout)
  
  return stdout
end

# See github issue #6: ohai gets the 'rev' info from /sys/block/sda/device/rev (see ohai/lib/ohai/plugins/linux/block_device.rb) and the data is actually truncated on some clusters
block_device.select { |key,value| key =~ /[sh]d.*/ and value["model"] != "vmDisk" }.each { |k,v|
  v['rev_from_hdparm'] = execute2("hdparm -I /dev/#{k}").grep(/Firmware Revision:/)[0].sub("Firmware Revision:", "").lstrip.rstrip rescue nil
}

