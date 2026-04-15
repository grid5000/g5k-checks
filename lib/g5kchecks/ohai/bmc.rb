# frozen_string_literal: true

require 'g5kchecks/utils/utils'
require 'g5kchecks/utils/bmc'

Ohai.plugin(:Bmc) do
  provides 'bmc'
  depends 'chassis'
  include Grid5000::BMC

  collect_data do
    bmc_info = fetch_info
    bmc Mash.new(bmc_info)
    bmc
  end
end
