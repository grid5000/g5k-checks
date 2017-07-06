describe "BMC" do

  before(:all) do
    @api = RSpec.configuration.node.api_description["network_adapters"].select { |na|
      na['management'] == true
    }[0] unless RSpec.configuration.node.api_description.empty?
    @ohai = RSpec.configuration.node.ohai_description[:network][:interfaces][:bmc] rescue nil
  end

  it "should have the correct IPv4" do
    ip_api = ""
    ip_ohai = ""
    ip_api = @api['ip'] if @api
    ip_ohai = @ohai['ip'] if @ohai
    Utils.test(ip_ohai, ip_api, "network_adapters/bmc/ip") do |v_ohai, v_api, error_msg|
      expect(v_ohai).to eql(v_api), error_msg
    end
  end

  it "should have the correct Mac Address" do
    mac_api = ""
    mac_ohai = ""
    mac_api = @api['mac'] if @api
    mac_ohai = @ohai['mac'] if @ohai
    Utils.test(mac_ohai, mac_api, "network_adapters/bmc/mac") do |v_ohai, v_api, error_msg|
      expect(v_ohai).to eql(v_api), error_msg
    end
  end

  it "should be a management card" do
    mgt_api = nil
    mgt_ohai = nil
    mgt_api = @api['management'] if @api
    mgt_ohai = @ohai['management'] if @ohai
    Utils.test(mgt_ohai, mgt_api, "network_adapters/bmc/management") do |v_ohai, v_api, error_msg|
      expect(v_ohai).to eql(v_api), error_msg
    end
  end
end
