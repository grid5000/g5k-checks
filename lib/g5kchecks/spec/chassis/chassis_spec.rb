# frozen_string_literal: true

describe 'Chassis' do
  before(:all) do
    @api = RSpec.configuration.node.api_description['chassis']
    @system = RSpec.configuration.node.ohai_description['dmi']['system']
  end

  it 'should have the correct serial number' do
    number_api = ''
    number_ohai = nil
    number_api = @api['serial'].to_s if @api
    number_ohai = @system['serial_number'].to_s.strip unless @system['serial_number'].nil?
    # si ohai (dmidecode) nous retourne empty alors on va chercher dans base_board
    # TODO move this to ohai
    if number_ohai.nil? || number_ohai.empty? || number_ohai == 'empty'
      number_ohai = RSpec.configuration.node.ohai_description['dmi']['base_board']['serial_number'].strip
    end
    number_ohai = '' if number_ohai == 'empty'
    Utils.test(number_ohai, number_api, 'chassis/serial') do |v_ohai, v_api, error_msg|
      expect(v_ohai).to eql(v_api), error_msg
    end
  end

  it 'should have the correct manufacturer' do
    manufacturer_api = ''
    manufacturer_api = @api['manufacturer'] if @api
    manufacturer_ohai = @system['manufacturer'].strip
    # TODO: move this to ohai
    if manufacturer_ohai.nil? || manufacturer_ohai.empty? || manufacturer_ohai == 'empty'
      manufacturer_ohai = RSpec.configuration.node.ohai_description['dmi']['base_board']['manufacturer'].strip
    end
    Utils.test(manufacturer_ohai, manufacturer_api, 'chassis/manufacturer') do |v_ohai, v_api, error_msg|
      expect(v_ohai).to eql(v_api), error_msg
    end
  end

  it 'should have the correct product name' do
    name_api = ''
    name_api = @api['name'] if @api
    name_ohai = @system['product_name'].strip
    # TODO: move this to ohai
    if name_ohai.nil? || name_ohai.empty? || name_ohai == 'empty'
      name_ohai = RSpec.configuration.node.ohai_description['dmi']['base_board']['product_name'].strip
    end
    Utils.test(name_ohai, name_api, 'chassis/name') do |v_ohai, v_api, error_msg|
      expect(v_ohai).to eql(v_api), error_msg
    end
  end
end
