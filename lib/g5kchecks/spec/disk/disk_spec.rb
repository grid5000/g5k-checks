describe "Disk" do

  before(:all) do
    @api = RSpec.configuration.node.api_description["storage_devices"]
  end

  RSpec.configuration.node.ohai_description.block_device.select { |key,value| key =~ /[sh]d.*/ and value["model"] != "vmDisk" }.each_with_index do |disk,i|

    it "should have the correct name" do
      name_ohai = disk[0]
      name_api = ""
      name_api = @api[i]["device"] if @api
      name_ohai.should eql(name_api), "#{name_ohai}, #{name_api}, block_devices, #{disk[0]}, device"
    end

    it "should have the correct size" do
      size_ohai = disk[1]["size"].to_i*512
      size_api = 0
      size_api = @api[i]["size"].to_i if @api
      size_ohai.should eql(size_api), "#{size_ohai}, #{size_api}, block_devices, #{disk[0]}, size"
    end

    it "should have the correct model" do
      model_ohai = disk[1]["model"]
      model_ohai.force_encoding("UTF-8")
      model_api = ""
      model_api = @api[i]['model'] if @api
      model_ohai.should eql(model_api), "#{model_ohai}, #{model_api}, block_devices, #{disk[0]}, model"
    end

    it "should have the correct revision" do
      version_ohai = disk[1]["rev"]
      version_ohai.force_encoding("UTF-8")
      version_api = ""
      version_api = @api[i]['rev'] if @api
      version_api = version_api.to_f if version_api.to_f != 0.0
      version_ohai = version_ohai.to_f if version_ohai.to_f != 0.0
      version_ohai.should eql(version_api), "#{version_ohai}, #{version_api}, block_devices, #{disk[0]}, rev"
    end

  end

end
