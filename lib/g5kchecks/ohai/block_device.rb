
require 'open3'
require 'json'

Ohai.plugin(:Blockdevice) do

  provides "block_device/improve"
  depends "block_device"

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

  collect_data do

    #
    # See github issue #6: finding the hard-drive vendor
    #
    #
    # See github issue #6: ohai gets the 'rev' info from /sys/block/sda/device/rev (see ohai/lib/ohai/plugins/linux/block_device.rb) and the data is actually truncated on some clusters
    # It is also truncated in lshw -class disk -class storage -json but value might be retrieve using hdparm
    #
    block_device.select { |key,value| key =~ /[sh]d.*/ and value["model"] != "vmDisk" }.each { |k,v|
      v['by_id'] = Utils.shell_out("find /dev/disk/by-id/ -lname '*#{k}' | grep '/wwn-'").stdout rescue nil
      v['by_path'] = Utils.shell_out("find /dev/disk/by-path/ -lname '*#{k}' | grep '/pci-'").stdout rescue nil
      stdout = utils.shell_out("hdparm -I /dev/#{k}").stdout
      v['rev_from_hdparm'] = stdout.grep(/Firmware Revision:/)[0].sub('Firmware Revision:', '').strip.encode!('utf-8', 'binary', :invalid => :replace, :undef => :replace, :replace => '') rescue nil
    }

    # Execute lshw
    lshw_hash = JSON.parse(Utils.shell_out("lshw -json").stdout.join("\n"))
    vendors = lshw_deep_search(lshw_hash) # {"/dev/sda"=>"Hitachi"}

    # Insert information into the ohai output
    block_device.select { |key,value| key =~ /[sh]d.*/ and value["model"] != "vmDisk" }.each { |k,v|
      if vendors.key?("/dev/#{k}") 
        v['vendor_from_lshw'] = vendors["/dev/#{k}"]
      end                       
    }
  end
end
