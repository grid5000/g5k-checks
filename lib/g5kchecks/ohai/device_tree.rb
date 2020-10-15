# frozen_string_literal: true

require 'g5kchecks/utils/utils'

Ohai.plugin(:DeviceTree) do
  provides 'devicetree'

  collect_data do
    devicetree Mash.new
    devicetree[:chassis] = Mash.new
    devicetree[:chassis][:product_name] = File.read('/proc/device-tree/model').strip
    devicetree[:chassis][:manufacturer] = File.read('/proc/device-tree/vendor').strip
    devicetree[:chassis][:serial_number] = File.read('/proc/device-tree/system-id').strip
  end
end
