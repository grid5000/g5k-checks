describe "Chassis" do

  before(:all) do
    @api = RSpec.configuration.node.api_description["chassis"]
    @system = RSpec.configuration.node.ohai_description.dmi["system"]
  end

  it "should have the correct serial number" do
    number_api = ""
    number_ohai = nil
    number_api = @api['serial'] if @api
    number_ohai = @system['serial_number'].chomp if @system['serial_number'] != "empty"
    number_ohai.should eq(number_api), "#{number_ohai}, #{number_api}, chassis, serial_number"
  end

  it "should have the correct manufacturer" do
    manufacturer_api = ""
    manufacturer_ohai = nil
    manufacturer_api = @api['manufacturer'] if @api
    manufacturer_ohai = @system['manufacturer'].chomp if @system['manufacturer'] != "empty"
    manufacturer_ohai.should eq(manufacturer_api), "#{manufacturer_ohai}, #{manufacturer_api}, chassis, manufacturer"
  end

  it "should have the correct product name" do
    name_api = ""
    name_ohai = nil
    name_api = @api['name'] if @api
    name_ohai = @system['product_name'].chomp if @system['product_name'] != "empty"
    name_ohai.should eq(name_api), "#{name_ohai}, #{name_api}, chassis, product_name"
  end

end
