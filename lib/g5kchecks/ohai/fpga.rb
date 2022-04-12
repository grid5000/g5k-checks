# frozen_string_literal: true

require 'g5kchecks/utils/utils'

Ohai.plugin(:Fpga) do
  provides 'other_devices'

  collect_data do
    # 1200 is the class ID of "Processing accelerators"
    # See: /usr/share/misc/pci.ids

    other_devices Mash.new(Utils.get_pci_infos(nil, nil, '1200'))
    other_devices.each do |slot, dev|
      dev['model'] = dev.delete('device')
      dev['type'] = 'fpga'
      dev['pci_slot'] = slot

      # Xilinx FPGA devices ids don't have (yet ?) names in pciutils
      dev['model'] = case dev['model']
                     when 'Device d000'
                       'Alveo U200'
                     else
                       raise 'FPGA model is not supported'
                     end
    end

    dev_index = -1
    other_devices.transform_keys! do
      dev_index += 1
      "fpga#{dev_index}"
    end

    other_devices
  end
end
