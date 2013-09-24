describe "Disk" do

  before(:all) do
    tmpapi = RSpec.configuration.node.api_description["storage_devices"]
    if tmpapi != nil
      @api = {}
      tmpapi.each{ |d|
        @api[d["device"]] = d
      }
    end
  end

  RSpec.configuration.node.ohai_description.block_device.select { |key,value| key =~ /[sh]d.*/ and value["model"] != "vmDisk" }.each { |k,v|

    it "should have the correct name" do
      name_api = @api[k] if @api
      name_api.should_not eql(nil), "#{k}, not_exist, block_devices, #{k}, device"
    end

    it "should have the correct size" do
      size_ohai = v["size"].to_i*512
      size_api = 0
      size_api = @api[k]["size"].to_i if (@api and @api[k] and @api[k]["size"])
      size_ohai.should eql(size_api), "#{size_ohai}, #{size_api}, block_devices, #{k}, size"
    end

    it "should have the correct model" do
      model_ohai = v['model']
      model_api = ""
      model_api = @api[k]['model'] if (@api and @api[k] and @api[k]['model'])
      model_ohai.should eql(model_api), "#{model_ohai}, #{model_api}, block_devices, #{k}, model"
    end

    it "should have the correct revision" do
      version_ohai = v["rev"]
      version_api = ""
      version_api = @api[k]['rev'] if (@api and @api[k] and @api[k]['rev'])
      version_api = version_api.to_f if version_api.to_f != 0.0
      version_ohai = version_ohai.to_f if version_ohai.to_f != 0.0
      version_ohai.should eql(version_api), "#{version_ohai}, #{version_api}, block_devices, #{k}, rev"
    end

  }

end
