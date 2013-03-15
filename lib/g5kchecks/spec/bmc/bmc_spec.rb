describe "BMC" do

  before(:all) do
    @api = RSpec.configuration.node.api_description["network_adapters"].select { |na|
      na['management'] == true
    }[0] unless RSpec.configuration.node.api_description.empty?
    @ohai = RSpec.configuration.node.ohai_description[:network][:interfaces][:mgt].to_hash
  end

    it "should have the correct IPv4" do
      ip_api = ""
      ip_api = @api['ip'] if @api
      ip_lshw = @ohai['ip']
      ip_lshw.should eql(ip_api), "#{ip_lshw}, #{ip_api}, network_interfaces, bmc, ip"
    end

    it "should have the correct Mac Address" do
      mac_api = ""
      mac_api = @api['mac'] if @api
      mac_lshw = @ohai['mac']
      mac_lshw.should eql(mac_api), "#{mac_lshw}, #{mac_api}, network_interfaces, bmc, mac"
    end

    it "should not be a management card" do
      mgt_api = nil
      mgt_api = @api['management'] if @api
      mgt_lshw = @ohai[:management]
      mgt_lshw.should eql(mgt_api), "#{mgt_lshw}, #{mgt_api}, network_interfaces, bmc, management"
    end

end

