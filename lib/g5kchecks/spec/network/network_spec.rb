describe "Network" do

  before(:all) do
    @api_desc = RSpec.configuration.node.api_description["network_adapters"]
    @api = {}
    if @api_desc
      @api_desc.each { |a|
        @api[a['device']] = a
      }
    end
  end

  RSpec.configuration.node.ohai_description[:network][:interfaces].to_hash.select { |d,i| %w{ eno eth ib myri }.include?(i[:type]) }.each do |dev|

    it "should be the correct interface name" do
      name_api = ""
      name_api = @api[dev[0]]['interface'] if @api_desc
      name_ohai = Utils.interface_name(dev[1][:type])
      name_ohai.should eql(name_api), "#{name_ohai}, #{name_api}, network_adapters, #{dev[0]}, interface"
    end

    it "should have the correct IPv4" do
      ip_api = ""
      ip_api = @api[dev[0]]['ip'] if @api_desc
      ip_ohai = dev[1][:ip]
      ip_ohai.should eql(ip_api), "#{ip_ohai}, #{ip_api}, network_adapters, #{dev[0]}, ip"
    end

    it "should have the correct IPv6" do
      ip_api = ""
      ip_api = @api[dev[0]]['ip6'] if @api_desc
      ip_ohai = dev[1][:ip6]
      ip_ohai.should eql(ip_api), "#{ip_ohai}, #{ip_api}, network_adapters, #{dev[0]}, ip6"
    end

    it "should have the correct Driver" do
      driver_api = ""
      driver_api = @api[dev[0]]['driver'] if @api_desc
      driver_ohai = dev[1][:driver]
      driver_ohai.should eql(driver_api), "#{driver_ohai}, #{driver_api}, network_adapters, #{dev[0]}, driver"
    end

    if dev[0] =~ /ib/
      it "should have the correct guid" do
      mac_api = ""
      mac_api = @api[dev[0]]['guid'] if @api_desc
      mac_ohai = dev[1][:mac]
      mac_ohai.should eql(mac_api), "#{mac_ohai}, #{mac_api}, network_adapters, #{dev[0]}, guid"
    end
    else
      it "should have the correct Mac Address" do
        mac_api = ""
        mac_api = @api[dev[0]]['mac'] if @api_desc
        mac_ohai = dev[1][:mac].downcase
        mac_ohai.should eql(mac_api), "#{mac_ohai}, #{mac_api}, network_adapters, #{dev[0]}, mac"
      end
    end

    it "should have the correct Rate" do
      rate_api = ""
      rate_api = @api[dev[0]]['rate'] if @api_desc
      if dev[1][:rate] == ""
        rate_ohai = dev[1][:rate]
      else
        rate_ohai = dev[1][:rate].to_i
      end
      rate_ohai.should eql(rate_api), "#{rate_ohai}, #{rate_api}, network_adapters, #{dev[0]}, rate"
    end

    it "should have the correct version" do
      ver_api = ""
      ver_api = @api[dev[0]]['version'] if @api_desc
      ver_ohai = dev[1][:version]
      ver_ohai.should eql(ver_api), "#{ver_ohai}, #{ver_api}, network_adapters, #{dev[0]}, version"
    end

    it "should have the correct vendor" do
      ven_api = ""
      ven_api = @api[dev[0]]['vendor'] if @api_desc
      ven_ohai = dev[1][:vendor]
      ven_ohai.should eql(ven_api), "#{ven_ohai}, #{ven_api}, network_adapters, #{dev[0]}, vendor"
    end

#    it "should have the correct enabled mode" do
#      ven_api = nil
#      ven_api = @api[dev[0]]['enabled'] if @api_desc
#      ven_ohai = dev[1][:enabled]
#      ven_ohai.should eql(ven_api), "#{ven_ohai}, #{ven_api}, network_adapters, #{dev[0]}, enabled"
#    end

#    it "should have the correct mountable mode" do
#      ven_api = nil
#      ven_api = @api[dev[0]]['mountable'] if @api_desc
#      ven_ohai = dev[1][:mountable]
#      ven_ohai.should eql(ven_api), "#{ven_ohai}, #{ven_api}, network_adapters, #{dev[0]}, mountable"
#    end

    it "should have the correct mounted mode" do
      ven_api = nil
      ven_api = @api[dev[0]]['mounted'] if @api_desc
      ven_ohai = dev[1][:mounted]
      ven_ohai.should eql(ven_api), "#{ven_ohai}, #{ven_api}, network_adapters, #{dev[0]}, mounted"
    end

    it "should not be a management card" do
      mgt_api = nil
      mgt_api = @api[dev[0]]['management'] if @api_desc
      mgt_ohai = dev[1][:management]
      mgt_ohai.should eql(mgt_api), "#{mgt_ohai}, #{mgt_api}, network_adapters, #{dev[0]}, management"
    end

  end

end
