# frozen_string_literal: true

require 'g5kchecks/utils/utils'

# If ohai (dmidecode) returns nothing for some chassis' entries, we take them
# from `base_board`.
# This plugin modify the `dmi` data structure if such case happens.
Ohai.plugin(:DMIExtend) do
  provides 'dmi'
  depends 'dmi'

  collect_data do
    system = dmi['system']
    ['serial_number', 'product_name', 'manufacturer'].each do |item|
      if system[item].nil? || system[item].empty? ||
          system[item] == 'empty'
        dmi['system'][item] = dmi['base_board'][item]
      end
    end
  end
end
