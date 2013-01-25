describe "Network" do

  before(:all) do
    @net_api = RSpec.configuration.node.api_description["network_adapters"]
  end

  RSpec.configuration.node.ohai_description[:network][:interfaces].to_hash.select { |d,i| %w{ eth br ib myri }.include?(i[:type]) }.each_with_index do |dev,i|

    it "should be the correct interface name" do
      name_api = ""
      name_api = @net_api[i]['interface'] if @net_api
      name_lshw = Utils.interface_name(dev[1][:type])
      name_lshw.should eql(name_api), "#{name_lshw}, #{name_api}, network_adapters, #{i}, interface"
    end

    it "should have the correct IPv4" do
      ip_api = ""
      ip_api = @net_api[i]['ip'] if @net_api
      ip_lshw = dev[1][:ip]
      ip_lshw.should eql(ip_api), "#{ip_lshw}, #{ip_api}, network_adapters, #{i}, ip"
    end

    it "should have the correct IPv6" do
      ip_api = ""
      ip_api = @net_api[i]['ip6'] if @net_api
      ip_lshw = dev[1][:ip6]
      ip_lshw.should eql(ip_api), "#{ip_lshw}, #{ip_api}, network_adapters, #{i}, ip6"
    end

    it "should have the correct Driver" do
      driver_api = ""
      driver_api = @net_api[i]['driver'] if @net_api
      driver_lshw = dev[1][:driver]
      driver_lshw.should eql(driver_api), "#{driver_lshw}, #{driver_api}, network_adapters, #{i}, driver"
    end

    it "should have the correct Mac Address" do
      mac_api = ""
      mac_api = @net_api[i]['mac'] if @net_api
      mac_lshw = dev[1][:mac]
      mac_lshw.should eql(mac_api), "#{mac_lshw}, #{mac_api}, network_adapters, #{i}, mac"
    end

    it "should have the correct Rate" do
      rate_api = ""
      rate_api = @net_api[i]['rate'] if @net_api
      rate_lshw = dev[1][:rate].to_i
      rate_lshw.should eql(rate_api), "#{rate_lshw}, #{rate_api}, network_adapters, #{i}, rate"
    end

    it "should have the correct version" do
      ver_api = ""
      ver_api = @net_api[i]['version'] if @net_api
      ver_lshw = dev[1][:version]
      ver_lshw.should eql(ver_api), "#{ver_lshw}, #{ver_api}, network_adapters, #{i}, version"
    end

    it "should have the correct vendor" do
      ven_api = ""
      ven_api = @net_api[i]['vendor'] if @net_api
      ven_lshw = dev[1][:vendor]
      ven_lshw.should eql(ven_api), "#{ven_lshw}, #{ven_api}, network_adapters, #{i}, vendor"
    end

    it "should have the correct enabled mode" do
      ven_api = nil
      ven_api = @net_api[i]['enabled'] if @net_api
      ven_lshw = dev[1][:enabled]
      ven_lshw.should eql(ven_api), "#{ven_lshw}, #{ven_api}, network_adapters, #{i}, enabled"
    end

    it "should have the correct mountable mode" do
      ven_api = nil
      ven_api = @net_api[i]['mountable'] if @net_api
      ven_lshw = dev[1][:mountable]
      ven_lshw.should eql(ven_api), "#{ven_lshw}, #{ven_api}, network_adapters, #{i}, mountable"
    end

    it "should have the correct mounted mode" do
      ven_api = nil
      ven_api = @net_api[i]['mounted'] if @net_api
      ven_lshw = dev[1][:mounted]
      ven_lshw.should eql(ven_api), "#{ven_lshw}, #{ven_api}, network_adapters, #{i}, mounted"
    end

  end

end
