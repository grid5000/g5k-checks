describe "OS" do

  before(:all) do
    @api = RSpec.configuration.node.api_description["operating_system"]
    @system = RSpec.configuration.node.ohai_description
  end

  [:ht_enabled, 
   :pstate_driver, :pstate_governor, #, :pstate_max_cpu_speed, :pstate_min_cpu_speed, 
   :turboboost_enabled, 
   :cstate_driver, :cstate_governor, :cstate_max_id].each { |key|

    it "should have the correct value for #{key}" do
      key_ohai = @system[:cpu][key]
      key_api = nil
      key_api = @api[key.to_s] if @api

      Utils.test(key_ohai, key_api, "operating_system/#{key}") do |v_ohai, v_api, error_msg|
        expect(v_ohai).to eql(v_api), error_msg
      end
    end
  }
end
