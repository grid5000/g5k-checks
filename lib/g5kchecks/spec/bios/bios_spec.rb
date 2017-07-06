describe "Bios" do

  before(:all) do
    @api = RSpec.configuration.node.api_description["bios"]
    @system = RSpec.configuration.node.ohai_description["dmi"]["bios"]
    @system2 = RSpec.configuration.node.ohai_description
  end

  it "should have the correct vendor" do
    vendor_api = ""
    vendor_api = @api['vendor'] if @api
    vendor_ohai = @system['vendor']
    Utils.test(vendor_ohai, vendor_api, "bios/vendor") do |v_ohai, v_api, error_msg|
      expect(v_ohai).to eql(v_api), error_msg
    end
  end

  it "should have the correct version" do
    version_api = ""
    version_api = @api['version'] if @api
    version_ohai = @system['version'].gsub(/'/,'').strip
    version_ohai = Utils.string_to_object(version_ohai.to_s)
    version_api  = Utils.string_to_object(version_api.to_s)
    Utils.test(version_ohai, version_api, "bios/version") do |v_ohai, v_api, error_msg|
      expect(v_ohai).to eql(v_api), error_msg
    end
  end

  it "should have the correct release date" do
    release_api = ""
    release_api = @api['release_date'] if @api
    release_ohai = @system['release_date']
    Utils.test(release_ohai, release_api, "bios/release_date")  do |v_ohai, v_api, error_msg|
      expect(v_ohai).to eql(v_api), error_msg
    end
  end

  [:ht_enabled, :turboboost_enabled, :cstate_c1e, :cstate_enabled].each { |key|

    it "should have the correct value for #{key}" do
      key_ohai = @system2[:cpu]['configuration'][key]
      key_api = nil
      key_api = @api['configuration'][key.to_s] if @api && @api.key?('configuration')
      Utils.test(key_ohai, key_api, "bios/configuration/#{key}")  do |v_ohai, v_api, error_msg|
        expect(v_ohai).to eql(v_api), error_msg
      end
    end
  }
end
