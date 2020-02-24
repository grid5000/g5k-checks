require 'g5kchecks/utils/utils'
require 'g5kchecks/utils/bmc'

Ohai.plugin(:Bmc) do

  provides "bmc"

  collect_data do
    bmc_info = Grid5000::BMC.new().fetch_info()
    bmc Mash.new(bmc_info)
    bmc
  end
end
