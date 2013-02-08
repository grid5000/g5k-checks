describe "BMC" do

  before(:all) do
    @api = RSpec.configuration.node.api_description["network_adapters"].select { |na|
      na['management'] == true
    }[0]
    @ohai = RSpec.configuration.node.ohai_description[:network][:interfaces][:mgt].to_hash
  end

    it "should have the correct IPv4" do
      ip_api = ""
      ip_api = @api['ip'] if @api
      ip_lshw = @ohai[:ip]
      ip_lshw.should eql(ip_api), "#{ip_lshw}, #{ip_api}, network_adapters, bmc, ip"
    end

    it "should have the correct Mac Address" do
      mac_api = ""
      mac_api = @api['mac'] if @api
      mac_lshw = @ohai[:mac]
      mac_lshw.should eql(mac_api), "#{mac_lshw}, #{mac_api}, network_adapters, bmc, mac"
    end

end

