# frozen_string_literal: true

describe 'Chassis' do
  before(:all) do
    @api = RSpec.configuration.node.api_description['chassis']
    @system = if Utils.dmi_supported?
                RSpec.configuration.node.ohai_description['dmi']['system']
              else
                RSpec.configuration.node.ohai_description['devicetree']['chassis']
              end
  end

  it 'should have the correct serial number' do
    number_api = ''
    number_api = @api['serial'].to_s if @api
    number_ohai = @system['serial_number'].to_s.strip

    Utils.test(number_ohai, number_api, 'chassis/serial') do |v_ohai, v_api, error_msg|
      expect(v_ohai).to eql(v_api), error_msg
    end
  end

  it 'should have the correct manufacturer' do
    manufacturer_api = ''
    manufacturer_api = @api['manufacturer'] if @api
    manufacturer_ohai = @system['manufacturer'].strip

    Utils.test(manufacturer_ohai, manufacturer_api, 'chassis/manufacturer') do |v_ohai, v_api, error_msg|
      expect(v_ohai).to eql(v_api), error_msg
    end
  end

  it 'should have the correct product name' do
    name_api = ''
    name_api = @api['name'] if @api
    name_ohai = @system['product_name'].strip

    Utils.test(name_ohai, name_api, 'chassis/name') do |v_ohai, v_api, error_msg|
      expect(v_ohai).to eql(v_api), error_msg
    end
  end
end
