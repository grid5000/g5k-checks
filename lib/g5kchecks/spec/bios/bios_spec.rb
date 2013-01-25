describe "Bios" do

  before(:all) do
    @bios_api = RSpec.configuration.node.api_description["bios"]
    @bios_lshw = RSpec.configuration.node.ohai_description.dmi["bios"]
  end

    it "should be the correct vendor" do
      vendor_api = ""
      vendor_api = @bios_api['vendor'] if @bios_api
      vendor_lshw = @bios_lshw['vendor']
      vendor_lshw.should eql(vendor_api), "#{vendor_lshw}, #{vendor_api}, bios, vendor"
    end

    it "should be the correct version" do
      version_api = ""
      version_api = @bios_api['version'] if @bios_api
      version_lshw = @bios_lshw['version']
      version_lshw.should eql(version_api), "#{version_lshw}, #{version_api}, bios, version"
    end

    it "should be the correct date release" do
      release_api = ""
      release_api = @bios_api['release_date'] if @bios_api
      release_lshw = @bios_lshw['release_date']
      release_lshw.should eql(release_api), "#{release_lshw}, #{release_api}, bios, release_date"
    end

end
