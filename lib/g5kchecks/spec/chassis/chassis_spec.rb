describe "Chassis" do

  before(:all) do
    @api = RSpec.configuration.node.api_description["chassis"]
    @sytem = RSpec.configuration.node.ohai_description.dmi["system"]
  end

  it "should be the correct serial number" do
    number_api = ""
    number_lshw = nil
    number_api = @api['serial'] if @api
    number_lshw = @sytem['serial_number'] if @sytem['serial_number'] != "empty"
    number_lshw.should eq(number_api), "#{number_lshw}, #{number_api}, chassis, serial_number"
  end

  it "should be the correct manufacturer" do
    manufacturer_api = ""
    manufacturer_lshw = nil
    manufacturer_api = @api['manufacturer'] if @api
    manufacturer_lshw = @sytem['manufacturer'] if @sytem['manufacturer'] != "empty"
    manufacturer_lshw.should eq(manufacturer_api), "#{manufacturer_lshw}, #{manufacturer_api}, chassis, manufacturer"
  end

  it "should be the correct product name" do
    name_api = ""
    name_lshw = nil
    name_api = @api['name'] if @api
    name_lshw = @sytem['product_name'] if @sytem['product_name'] != "empty"
    name_lshw.should eq(name_api), "#{name_lshw}, #{name_api}, chassis, product_name"
  end

end
