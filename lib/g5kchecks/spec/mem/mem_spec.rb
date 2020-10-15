# frozen_string_literal: true

describe 'Memory' do
  before do
    @api = RSpec.configuration.node.api_description['main_memory']
  end

  it 'should have the correct ram size' do
    size_api = 0
    size_api = @api['ram_size'].to_i if @api
    size_sys = if Utils.dmi_supported?
                 Utils.dmidecode_total_memory(:dram)
               else
                 Utils.meminfo_total_memory(:dram)
               end

    err = ((size_sys - size_api) / size_api.to_f).abs
    Utils.test(size_sys, size_api, 'main_memory/ram_size') do |_v_ohai, _v_api, error_msg|
      expect(err).to be < 0.15, error_msg
    end
  end

  it 'should have the correct pmem size' do
    size_api = 0
    size_api = @api['pmem_size'].to_i if @api
    size_sys = if Utils.dmi_supported?
                 Utils.dmidecode_total_memory(:pmem)
               else
                 Utils.meminfo_total_memory(:pmem)
               end

    unless size_sys.nil? && (size_api == 0)
      err = ((size_sys - size_api) / size_api.to_f).abs
      Utils.test(size_sys, size_api, 'main_memory/pmem_size') do |_v_ohai, _v_api, error_msg|
        expect(err).to be < 0.15, error_msg
      end
    end
  end
end
