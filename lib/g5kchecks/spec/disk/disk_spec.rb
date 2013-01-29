require 'g5kchecks/utils/utils'

describe "Disk" do

  before(:all) do
    @disk_api = RSpec.configuration.node.api_description["storage_devices"]
    #    @disk_lshw = RSpec.configuration.node.search_all_in_hw_description("id","disk")
  end

  RSpec.configuration.node.ohai_description.block_device.select { |key,value| key =~ /[sh]d.*/ }.each_with_index{|disk,i|

    it "should have the correct name" do
      name_lshw = disk[0]
      name_api = ""
      if @disk_api
        name_api = @disk_api[i]["device"]
      end
      name_lshw.should eql(name_api), "#{name_lshw}, #{name_api}, storage_devices, #{i}, device"
    end

    it "should have the correct size" do
      size_lshw = disk[1]["size"].to_i*512
      size_api = 0
      if @disk_api
        size_api = Utils.convert_storage(@disk_api[i]["size"].to_i)
      end
      size_lshw.should eql(size_api), "#{size_lshw}, #{size_api}, storage_devices, #{i}, size"
    end

    it "should have the correct model" do
      model_lshw = disk[1]["model"]
      model_lshw.force_encoding("UTF-8")
      model_api = ""
      if @disk_api
        model_api = @disk_api[i]['model']
      end
      model_lshw.should eql(model_api), "#{model_lshw}, #{model_api}, storage_devices, #{i}, model"
    end

    it "should have the correct version" do
      version_lshw = disk[1]["rev"]
      version_lshw.force_encoding("UTF-8")
      version_api = ""
      if @disk_api
        version_api = @disk_api[i]['rev']
      end
      version_lshw.should eql(version_api), "#{version_lshw}, #{version_api}, storage_devices, #{i}, rev"
    end

    #  it "should have the correct controller" do
    #      controller_lshw = disk["description"][0]
    #      controller_api = ""
    #      if @disk_api
    #        controller_api = @disk_api[i]['interface']
    #      end
    #      controller_lshw.should eql(controller_api), controller_lshw
    #  end

    #  it "should have the correct driver" do
    #      driver_lshw = disk["driver"][0]
    #      driver_api = ""
    #      if @disk_api
    #        driver_api = @disk_api[i]['driver']
    #      end
    #      driver_lshw.should eql(driver_api), driver_lshw
    #  end
  }
end
