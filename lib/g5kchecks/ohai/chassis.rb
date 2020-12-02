# frozen_string_literal: true

require 'g5kchecks/utils/utils'

# Generate chassis by taking from dmi or devicetree

Ohai.plugin(:Chassis) do
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

    # Looks not possible to juste make a simple assignment, even with dup.
    # The Mash is populate but ohai return a empty one.
    chassis_data.each_pair { |k, v| chassis[k] = v }
  end
end
