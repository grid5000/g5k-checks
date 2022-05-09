# frozen_string_literal: true

require 'g5kchecks/utils/utils'

Ohai.plugin(:Fpga) do
  provides 'other_devices'

  collect_data do
    # 1200 is the class ID of "Processing accelerators"
    # See: /usr/share/misc/pci.ids

    other_devices_pci_infos Mash.new(Utils.get_pci_infos(nil, nil, '1200'))
    other_devices_pci_infos.each do |slot, dev|
      dev['model'] = dev.delete('device')
      dev['type'] = 'fpga'
      dev['pci_slot'] = slot

      # Xilinx FPGA devices ids don't have (yet ?) names in pciutils
      dev['model'] = case dev['model']
                     when /Device 500[0-9]/, 'Device d000'
                       'Alveo U200'
                     else
                       raise 'FPGA model is not supported'
                     end
    end

    other_devices_by_phy_slot = Mash.new
    other_devices_pci_infos.each do |_, dev|
      other_devices_by_phy_slot[dev['phy_slot']] ||= []
      other_devices_by_phy_slot[dev['phy_slot']] << dev
    end

    other_devices Mash.new
    other_devices_by_phy_slot.each do |_, dev|
      first_pci_dev = dev.sort_by { |d| d[:pci_slot] }[0]
      other_devices[first_pci_dev[:pci_slot]] = first_pci_dev
    end

    dev_index = -1
    other_devices.transform_keys! do
      dev_index += 1
      "fpga#{dev_index}"
    end

    other_devices
  end
end
