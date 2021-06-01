# frozen_string_literal: true

require 'g5kchecks/utils/utils'
require 'g5kchecks/utils/gpu'

Ohai.plugin(:Gpu) do
  provides 'gpu_devices'

  collect_data do
    cards = Grid5000::NvidiaGpu.new.fetch_nvidia_cards_info
    cards.merge!(Grid5000::AmdGpu.new.fetch_amdgpu_cards_info)
    gpu_devices Mash.new(cards)
    gpu_devices
  end
end
