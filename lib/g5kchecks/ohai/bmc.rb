# frozen_string_literal: true

require 'g5kchecks/utils/utils'
require 'g5kchecks/utils/bmc'

Ohai.plugin(:Bmc) do
  provides 'bmc'
  depends 'chassis'

  collect_data do
    bmc_info = Grid5000::BMC.new.fetch_info(chassis)
    bmc Mash.new(bmc_info)
    bmc
  end
end
