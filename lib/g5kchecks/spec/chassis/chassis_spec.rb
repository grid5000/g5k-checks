# -*- coding: utf-8 -*-
describe "Chassis" do

  before(:all) do
    @api = RSpec.configuration.node.api_description["chassis"]
    @system = RSpec.configuration.node.ohai_description["dmi"]["system"]
  end

  it "should have the correct serial number" do
    number_api = ""
    number_ohai = nil
    number_api = @api['serial'].to_s if @api
    number_ohai = @system['serial_number'].to_s.strip unless @system['serial_number'].nil?
    # si ohai nous retourne empty alors on va chercher dans base_board
    if number_ohai == "empty"
      number_ohai = RSpec.configuration.node.ohai_description["dmi"]['base_board']['serial_number'].strip
      # si c'est toujours empty alors on n'effectue pas le test (la bonne valeur est peut-être dans l'API
      expect(number_ohai).to eq(number_api), "#{number_ohai}, #{number_api}, chassis, serial" if number_ohai != "empty"
    else
      expect(number_ohai).to eq(number_api), "#{number_ohai}, #{number_api}, chassis, serial"
    end
  end

  it "should have the correct manufacturer" do
    manufacturer_api = ""
    manufacturer_ohai = nil
    manufacturer_api = @api['manufacturer'] if @api
    manufacturer_ohai = @system['manufacturer'].strip
    if manufacturer_ohai == "empty"
      manufacturer_ohai = RSpec.configuration.node.ohai_description["dmi"]['base_board']['manufacturer'].strip
      expect(manufacturer_ohai).to eq(manufacturer_api), "#{manufacturer_ohai}, #{manufacturer_api}, chassis, manufacturer" if manufacturer_ohai != "empty"
    else
      expect(manufacturer_ohai).to eq(manufacturer_api), "#{manufacturer_ohai}, #{manufacturer_api}, chassis, manufacturer"
    end
  end

  it "should have the correct product name" do
    name_api = ""
    name_ohai = nil
    name_api = @api['name'] if @api
    name_ohai = @system['product_name'].strip
    if name_ohai == "empty"
      name_ohai = RSpec.configuration.node.ohai_description.dmi['base_board']['product_name'].strip
      expect(name_ohai).to eq(name_api), "#{name_ohai}, #{name_api}, chassis, name" if name_ohai != "empty"
    else
      expect(name_ohai).to eq(name_api), "#{name_ohai}, #{name_api}, chassis, name"
    end
  end

end
