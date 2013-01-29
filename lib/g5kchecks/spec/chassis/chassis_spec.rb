describe "Chassis" do

  before(:all) do
    @chassis_api = RSpec.configuration.node.api_description["bios"]
    @chassis_lshw = RSpec.configuration.node.ohai_description.dmi["system"]
  end

  it "should be the correct serial number" do
    number_api = ""
    number_lshw = nil
    number_api = @chassis_api['serial_number'] if @chassis_api
    number_lshw = @chassis_lshw['serial_number'] if @chassis_lshw['serial_number'] != "empty"
    number_lshw.should eq(number_api), "#{number_lshw}, #{number_api}, chassis, serial_number"
  end

  it "should be the correct manufacturer" do
    manufacturer_api = ""
    manufacturer_lshw = nil
    manufacturer_api = @chassis_api['manufacturer'] if @chassis_api
    manufacturer_lshw = @chassis_lshw['manufacturer'] if @chassis_lshw['manufacturer'] != "empty"
    manufacturer_lshw.should eq(manufacturer_api), "#{manufacturer_lshw}, #{manufacturer_api}, chassis, manufacturer"
  end

  it "should be the correct product name" do
    name_api = ""
    name_lshw = nil
    name_api = @chassis_api['product_name'] if @chassis_api
    name_lshw = @chassis_lshw['product_name'] if @chassis_lshw['product_name'] != "empty"
    name_lshw.should eq(name_api), "#{name_lshw}, #{name_api}, chassis, product_name"
  end

end
