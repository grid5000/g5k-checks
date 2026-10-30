# frozen_string_literal: true

require 'json'
require 'peach'

Ohai.plugin(:Blockdevice) do
  provides 'block_device/improve'
  depends 'block_device'

  # a raid volume reports the rotational flag of the controller, not of the disks.
  # ask smartctl for the first physical disk behind the controller instead
  def raid_storage_type(name)
    # smartctl device type for each scsi host driver of a hardware raid controller
    raid_drivers = {
      'megaraid_sas' => 'megaraid', # dell perc, lenovo, broadcom megaraid
      'hpsa' => 'cciss',            # hpe smart array
      'smartpqi' => 'cciss'         # hpe smart array gen10+
    }

    sys_device = "/sys/block/#{name}/device"
    return nil unless File.exist?(sys_device)

    host = File.basename(File.realpath(sys_device)).split(':').first
    proc_name = "/sys/class/scsi_host/host#{host}/proc_name"
    return nil unless File.exist?(proc_name)

    smart_type = raid_drivers[File.read(proc_name).strip]
    return nil if smart_type.nil?

    rotation = shell_out("smartctl -i -d #{smart_type},0 /dev/#{name}").stdout[/^Rotation Rate:\s*(.+)$/, 1]
    return nil if rotation.nil?

    rotation.include?('Solid State') ? 'SSD' : 'HDD'
  end

  collect_data do
    #
    # See github issue #6: finding the hard-drive vendor
    # See github issue #6: ohai gets the 'rev' info from /sys/block/sda/device/rev (see ohai/lib/ohai/plugins/linux/block_device.rb) and the data is actually truncated on some clusters
    #
    block_device.select { |key, value| (key =~ /[sh]d.*/ || key =~ /nvme.*/) && (value['model'] != 'vmDisk') }.peach do |k, v|
      id = shell_out("find /dev/disk/by-id/ -lname '*#{k}'").stdout.split("\n").grep(%r{/(wwn-|nvme-eui)}).first
      v['by_id'] = id || '' # empty string if nil
      v['by_path'] = shell_out("find /dev/disk/by-path/ -lname '*#{k}'").stdout.split("\n").grep(%r{/(platform-.*pcie-)?pci-}).sort.first
      stdout = shell_out("hdparm -I /dev/#{k}").stdout.encode!('utf-8', 'binary', invalid: :replace, undef: :replace, replace: '')
      firmware_revision = stdout.split("\n").grep(/Firmware Revision/).first
      next if firmware_revision.nil?

      rev_from_hdparm = firmware_revision.chomp.sub('Firmware Revision:', '').strip
      # in case ohai rev is a truncated value
      if !rev_from_hdparm.nil? && !v['rev'].nil? && !v['rev'].empty?
        v['rev'] = rev_from_hdparm if rev_from_hdparm.include?(v['rev'])
      end
    end

    block_device.each do |name, value|
      value['storage'] = raid_storage_type(name) || (value['rotational'].to_i.zero? ? 'SSD' : 'HDD')
    end
  end
end
