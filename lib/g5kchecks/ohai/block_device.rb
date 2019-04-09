
require 'json'

Ohai.plugin(:Blockdevice) do

  provides "block_device/improve"
  depends "block_device"

  collect_data do

    #
    # See github issue #6: finding the hard-drive vendor
    # See github issue #6: ohai gets the 'rev' info from /sys/block/sda/device/rev (see ohai/lib/ohai/plugins/linux/block_device.rb) and the data is actually truncated on some clusters
    #
    block_device.select { |key,value| (key =~ /[sh]d.*/ or key =~ /nvme.*/) and value["model"] != "vmDisk" }.each { |k,v|
      id = Utils.shell_out("find /dev/disk/by-id/ -lname '*#{k}'").stdout.split("\n").grep(/\/(wwn-|nvme-eui)/).first
      v['by_id'] = id || '' # empty string if nil
      v['by_path'] = Utils.shell_out("find /dev/disk/by-path/ -lname '*#{k}'").stdout.split("\n").grep(/\/pci-/).first
      stdout = Utils.shell_out("hdparm -I /dev/#{k}").stdout.encode!('utf-8', 'binary', :invalid => :replace, :undef => :replace, :replace => '')
      firmware_revision = rev_from_hdparm = stdout.split("\n").grep(/Firmware Revision/).first
      if not firmware_revision.nil?
        rev_from_hdparm = firmware_revision.chomp.sub('Firmware Revision:', '').strip
        #in case ohai rev is a truncated value
        if (!rev_from_hdparm.nil? && !v['rev'].nil? && !v['rev'].empty?)
          if rev_from_hdparm.include?(v['rev'])
            v['rev'] = rev_from_hdparm
          end
        end
      end
    }
  end
end
