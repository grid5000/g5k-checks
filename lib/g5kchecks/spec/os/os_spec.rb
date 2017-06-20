describe "OS" do

  before(:all) do
    @api = RSpec.configuration.node.api_description["operating_system"]
    @system = RSpec.configuration.node.ohai_description
  end

  it "should be the correct name" do
    name_api = ""
    name_api = @api['name'] if @api
    name_ohai = @system[:platform]
    Utils.test(name_ohai, name_api, "operating_system.name") do |v_ohai, v_api, error_msg|
      expect(v_ohai).to eql(v_api), error_msg
    end
  end

  it "should be the correct kernel version" do
    kernel_api = ""
    kernel_api = @api['kernel'] if @api
    kernel_ohai = @system[:kernel][:release]
    Utils.test(kernel_ohai, kernel_api, "operating_system.kernel") do |v_ohai, v_api, error_msg|
      expect(v_ohai).to eql(v_api), error_msg
    end
  end

  it "should be the correct version" do
    release_api = ""
    release_api = @api['version'] if @api
    release_ohai = @system[:platform_version]
    release_api = release_api.to_s unless release_api.is_a? String # release_ohai is a string but is saved as a float on the yaml output of g5k-checks (?)
    Utils.test(release_ohai, release_api, "operating_system.version") do |v_ohai, v_api, error_msg|
      expect(v_ohai).to eql(v_api), error_msg
    end
  end

  [:ht_enabled, 
   :pstate_driver, :pstate_governor, #, :pstate_max_cpu_speed, :pstate_min_cpu_speed, 
   :turboboost_enabled, 
   :cstate_driver, :cstate_governor, :cstate_max_id].each { |key|
    
    it "should have the correct value for #{key}" do
      key_ohai = @system[:cpu][key]
      key_api = nil
      key_api = @api[key.to_s] if @api

      Utils.test(key_ohai, key_api, "operating_system.#{key}") do |v_ohai, v_api, error_msg|
        expect(v_ohai).to eql(v_api), error_msg
      end
    end
  }
end
