# -*- coding: utf-8 -*-
provides "block_device/improve"
require_plugin("block_device")

require 'open3'
require 'json'

# Execute an external program
def execute2(cmd)
  stdout, stderr, status = Open3.capture3(cmd)
  
  raise "#{cmd}: #{status.exitstatus}" unless status.success?
  
  stdout = stdout.split("\n")
  stdout = (stdout.size == 1 ? stdout[0] : stdout)
  
  return stdout
end

#
# See github issue #6: ohai gets the 'rev' info from /sys/block/sda/device/rev (see ohai/lib/ohai/plugins/linux/block_device.rb) and the data is actually truncated on some clusters
# It is also truncated in lshw -class disk -class storage -json but value might be retrieve using hdparm
#

block_device.select { |key,value| key =~ /[sh]d.*/ and value["model"] != "vmDisk" }.each { |k,v|
  v['by_id'] = execute2("find /dev/disk/by-id/ -lname '*#{k}' | grep '/wwn-'") rescue nil
  v['by_path'] = execute2("find /dev/disk/by-path/ -lname '*#{k}' | grep '/pci-'") rescue nil

  v['rev_from_hdparm'] = execute2("hdparm -I /dev/#{k}").grep(/Firmware Revision:/)[0].sub('Firmware Revision:', '').strip.encode!('utf-8', 'binary', :invalid => :replace, :undef => :replace, :replace => '') rescue nil
}

#
# See github issue #6: finding the hard-drive vendor
#                          

# Get disk/vendor pairs from the lshw output
def lshw_deep_search(h)
  vendors = {}
  
  if h['class'] == 'disk' && h.key?('vendor')
    vendors[h['logicalname']] = h['vendor']
  else
    h.each do |k, v|
      if v.is_a? Hash
        vendors.merge!(lshw_deep_search(v))
      elsif v.is_a? Array
        v.each do |vv|
          vendors.merge!(lshw_deep_search(vv)) if vv.is_a? Hash
        end
      end
    end
  end
  vendors
end

# Execute lshw
lshw_hash = JSON.parse(execute2("lshw -json").join("\n"))
vendors = lshw_deep_search(lshw_hash) # {"/dev/sda"=>"Hitachi"}

# Insert information into the ohai output
block_device.select { |key,value| key =~ /[sh]d.*/ and value["model"] != "vmDisk" }.each { |k,v|
  if vendors.key?("/dev/#{k}") 
    v['vendor_from_lshw'] = vendors["/dev/#{k}"]
  end                       
}                           
