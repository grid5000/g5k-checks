describe "OS" do

  before(:all) do
    @os_api = RSpec.configuration.node.api_description["operating_system"]
    @os_lshw = RSpec.configuration.node.ohai_description
  end

  it "should be the correct name" do
    name_api = ""
    name_api = @os_api['name'] if @os_api
    name_lshw = @os_lshw[:platform]
    name_lshw.should eql(name_api), "#{name_lshw}, #{name_api}, operating_system, name"
  end

  it "should be the correct kernel version" do
    kernel_api = ""
    kernel_api = @os_api['kernel'] if @os_api
    kernel_lshw = @os_lshw[:kernel][:version]
    kernel_lshw.should eql(kernel_api), "#{kernel_lshw}, #{kernel_api}, operating_system, kernel"
  end

  it "should be the correct release" do
    release_api = ""
    release_api = @os_api['release'] if @os_api
    release_lshw = @os_lshw[:platform_version]
    release_lshw.should eql(release_api), "#{release_lshw}, #{release_api}, operating_system, release"
  end

end
