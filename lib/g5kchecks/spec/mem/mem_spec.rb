# frozen_string_literal: true

describe 'Memory' do
  before(:all) do
    @api = RSpec.configuration.node.api_description['main_memory']
  end

  it 'should have the correct ram size' do
    size_api = 0
    size_api = @api['ram_size'].to_i if @api
    size_sys = if Utils.dmi_supported?
                 Utils.dmidecode_total_memory[:dram]
               else
                 Utils.lshw_total_memory(:dram)
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
                 Utils.dmidecode_total_memory[:pmem]
               else
                 Utils.lshw_total_memory(:pmem)
               end

    unless size_sys.nil? && (size_api == 0)
      err = ((size_sys - size_api) / size_api.to_f).abs
      Utils.test(size_sys, size_api, 'main_memory/pmem_size') do |_v_ohai, _v_api, error_msg|
        expect(err).to be < 0.15, error_msg
      end
    end
  end
end


describe 'MemoryDevices' do
  api_devices_array = RSpec.configuration.node.api_description['memory_devices']
  ohai_devices = if Utils.dmi_supported?
                   Utils.dmidecode_memory_devices
                 else
                   Utils.lshw_memory_devices
                 end

  api_devices = nil
  api_devices_array&.each do |d|
    api_devices ||= {}
    api_devices[d['device']] = d.transform_keys(&:to_sym)
  end

  reference_devices = api_devices.nil? ? ohai_devices : api_devices

  it 'should have the correct number of devices' do
    size_ohai = ohai_devices.length
    size_api = api_devices.nil? ? nil : api_devices.length
    Utils.test(size_ohai, size_api, "memory_devices/length", true) do |v_ohai, v_api, error_msg|
      expect(v_ohai).to eql(v_api), error_msg
    end
  end

  reference_devices.each_key do |name|
    it 'should have the correct size' do
      size_ohai = ohai_devices[name][:size]
      size_api = api_devices.nil? ? nil : api_devices[name][:size]
      Utils.test(size_ohai, size_api, "memory_devices/#{name}/size") do |v_ohai, v_api, error_msg|
        expect(v_ohai).to eql(v_api), error_msg
      end
    end

    it 'should have the correct firmware' do
      firmware_ohai = ohai_devices[name][:firmware]
      firmware_api = api_devices.nil? ? nil : api_devices[name][:firmware]
      Utils.test(firmware_ohai, firmware_api, "memory_devices/#{name}/firmware") do |v_ohai, v_api, error_msg|
        expect(v_ohai).to eql(v_api), error_msg
      end
    end

    it 'should have the correct technology' do
      technology_ohai = ohai_devices[name][:technology].to_s
      technology_api = api_devices.nil? ? nil : api_devices[name][:technology]
      Utils.test(technology_ohai, technology_api, "memory_devices/#{name}/technology") do |v_ohai, v_api, error_msg|
        expect(v_ohai).to eql(v_api), error_msg
      end
    end
  end
end

