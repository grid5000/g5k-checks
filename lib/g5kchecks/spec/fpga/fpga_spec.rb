# frozen_string_literal: true

describe 'Fpga' do
  api_fpga_devices = RSpec.configuration.node.api_description['other_devices']&.
    select{ |_, dev| dev['type'] == 'fpga'} || {}
  api_fpga_devices_by_dev = {}
  unless api_fpga_devices.empty?
    api_fpga_devices.each do |card|
      api_fpga_devices_by_dev[card[0]] = card[1]
    end
  end
  ohai_fpga_devices = RSpec.configuration.node.ohai_description[:other_devices]&.
    select { |_, dev| dev['type'] == 'fpga'}

  it 'should have the correct number of FPGA' do
    nb_fpga_ohai = ohai_fpga_devices.length
    nb_fpga_api = api_fpga_devices_by_dev.length
    Utils.test(nb_fpga_ohai, nb_fpga_api, 'number of FPGAs', true) do |v_ohai, v_api, error_msg|
      expect(v_ohai).to eql(v_api), error_msg
    end
  end

  ohai_fpga_devices.each do |dev, card|
    %w[vendor model type].each do |field|
      it "should have information about #{field} for #{dev}" do
        fpga_ohai = card[field.to_sym]
        fpga_api = api_fpga_devices_by_dev[dev].nil? ? nil : api_fpga_devices_by_dev[dev][field]
        Utils.test(fpga_ohai, fpga_api, "other_devices/#{dev}/#{field}") do |v_ohai, v_api, error_msg|
          expect(v_ohai).to eql(v_api), error_msg
        end
      end
    end
  end
end
