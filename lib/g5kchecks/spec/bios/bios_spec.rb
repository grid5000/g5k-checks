describe "Bios" do

  before(:all) do
    @api = RSpec.configuration.node.api_description["bios"]
    @system = RSpec.configuration.node.ohai_description.dmi["bios"]
  end

  it "should be the correct vendor" do
    vendor_api = ""
    vendor_api = @api['vendor'] if @api
    vendor_lshw = @system['vendor']
    vendor_lshw.should eql(vendor_api), "#{vendor_lshw}, #{vendor_api}, bios, vendor"
  end

  it "should be the correct version" do
    version_api = ""
    version_api = @api['version'] if @api
    version_lshw = @system['version']
    version_lshw.should eql(version_api), "#{version_lshw}, #{version_api}, bios, version"
  end

  it "should be the correct date release" do
    release_api = ""
    release_api = @api['release_date'] if @api
    release_lshw = @system['release_date']
    release_lshw.should eql(release_api), "#{release_lshw}, #{release_api}, bios, release_date"
  end

end
