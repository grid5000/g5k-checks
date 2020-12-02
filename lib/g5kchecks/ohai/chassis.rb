# frozen_string_literal: true

require 'g5kchecks/utils/utils'

Ohai.plugin(:ChassisExtend) do
  if Utils.dmi_supported?
    depends 'dmi'
  else
    depends 'devicetree'
  end
  provides 'chassis'

  collect_data do
    chassis Mash.new
    chassis_data = if Utils.dmi_supported?
                     dmi['system']
                   else
                     devicetree['chassis']
                   end
    chassis_data.each_pair { |k, v| chassis[k] = v }
  end
end
