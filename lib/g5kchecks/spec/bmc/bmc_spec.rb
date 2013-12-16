describe "BMC" do

  before(:all) do
    @api = RSpec.configuration.node.api_description["network_adapters"].select { |na|
      na['management'] == true
    }[0] unless RSpec.configuration.node.api_description.empty?
    @ohai = RSpec.configuration.node.ohai_description[:network][:interfaces][:mgt].to_hash
  end

    it "should have the correct IPv4" do
      ip_api = ""
      ip_ohai = ""
      ip_api = @api['ip'] if @api
      ip_ohai = @ohai['ip'] if @ohai 
      ip_ohai.should eql(ip_api), "#{ip_ohai}, #{ip_api}, network_interfaces, bmc, ip"
    end

    it "should have the correct Mac Address" do
      mac_api = ""
      mac_ohai = ""
      mac_api = @api['mac'] if @api
      mac_ohai = @ohai['mac'] if @ohai
      mac_ohai.should eql(mac_api), "#{mac_ohai}, #{mac_api}, network_interfaces, bmc, mac"
    end

    it "should be a management card" do
      mgt_api = ""
      mgt_ohai = ""
      mgt_api = @api['management'] if @api
      mgt_ohai = @ohai[:management] if @ohai
      mgt_ohai.should eql(mgt_api), "#{mgt_ohai}, #{mgt_api}, network_interfaces, bmc, management"
    end
end

