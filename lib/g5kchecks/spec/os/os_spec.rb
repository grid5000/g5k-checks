describe "OS" do

  before(:all) do
    @api = RSpec.configuration.node.api_description["operating_system"]
    @system = RSpec.configuration.node.ohai_description
  end

  it "should be the correct name" do
    name_api = ""
    name_api = @api['name'] if @api
    name_ohai = @system[:platform]
    name_ohai.should eql(name_api), "#{name_ohai}, #{name_api}, operating_system, name"
  end

  it "should be the correct kernel version" do
    kernel_api = ""
    kernel_api = @api['kernel'] if @api
    kernel_ohai = @system[:kernel][:release]
    kernel_ohai.should eql(kernel_api), "#{kernel_ohai}, #{kernel_api}, operating_system, kernel"
  end

  it "should be the correct version" do
    release_api = ""
    release_api = @api['version'] if @api
    release_ohai = @system[:platform_version]
    release_api = release_api.to_s unless release_api.is_a? String # release_ohai is a string but is saved as a float on the yaml output of g5k-checks (?)
    release_ohai.should eql(release_api), "#{release_ohai}, #{release_api}, operating_system, version"
  end

  [:ht_enabled, 
   :pstate_driver, :pstate_governor, #, :pstate_max_cpu_speed, :pstate_min_cpu_speed, 
   :turboboost_enabled, 
   :cstate_driver, :cstate_governor, :cstate_max_id].each { |key|
    
    it "should have the correct value for #{key}" do
      key_ohai = @system[:cpu][key]
      
      key_api = nil
      key_api = @api[key.to_s] if @api
      
      key_ohai.should eq(key_api), "#{key_ohai}, #{key_api}, operating_system, #{key}"
    end
  
  }

end
