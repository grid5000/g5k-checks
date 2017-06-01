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
      expect(name_ohai).to eql(name_api), "#{name_ohai}, #{name_api}, network_adapters, #{dev[0]}, interface"
    end

    it "should have the correct IPv4" do
      ip_api = ""
      ip_api = @api[dev[0]]['ip'] if @api_desc
      ip_ohai = dev[1][:ip]
      expect(ip_ohai).to eql(ip_api), "#{ip_ohai}, #{ip_api}, network_adapters, #{dev[0]}, ip"
    end

    it "should have the correct IPv6" do
      ip6_api = ""
      ip6_api = @api[dev[0]]['ip6'] if @api_desc
      ip6_ohai = dev[1][:ip6]
      expect(ip6_ohai).to eql(ip6_api), "#{ip6_ohai}, #{ip6_api}, network_adapters, #{dev[0]}, ip6"
    end

    it "should have the correct Driver" do
      driver_api = ""
      driver_api = @api[dev[0]]['driver'] if @api_desc
      driver_ohai = dev[1][:driver]
      expect(driver_ohai).to eql(driver_api), "#{driver_ohai}, #{driver_api}, network_adapters, #{dev[0]}, driver"
    end

    if dev[0] =~ /ib/
      it "should have the correct guid" do
        mac_api = ""
        mac_api = @api[dev[0]]['guid'] if @api_desc
        mac_ohai = dev[1][:mac]
        expect(mac_ohai).to eql(mac_api), "#{mac_ohai}, #{mac_api}, network_adapters, #{dev[0]}, guid"
      end
    else
      it "should have the correct Mac Address" do
        mac_api = ""
        mac_api = @api[dev[0]]['mac'] if @api_desc
        mac_ohai = dev[1][:mac].downcase
        expect(mac_ohai).to eql(mac_api), "#{mac_ohai}, #{mac_api}, network_adapters, #{dev[0]}, mac"
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
      expect(rate_ohai).to eql(rate_api), "#{rate_ohai}, #{rate_api}, network_adapters, #{dev[0]}, rate"
    end

    it "should have the correct version" do
      ver_api = ""
      ver_api = @api[dev[0]]['version'] if @api_desc
      ver_ohai = dev[1][:version]
      expect(ver_ohai).to eql(ver_api), "#{ver_ohai}, #{ver_api}, network_adapters, #{dev[0]}, version"
    end

    it "should have the correct vendor" do
      ven_api = ""
      ven_api = @api[dev[0]]['vendor'] if @api_desc
      ven_ohai = dev[1][:vendor]
      expect(ven_ohai).to eql(ven_api), "#{ven_ohai}, #{ven_api}, network_adapters, #{dev[0]}, vendor"
    end

    it "should have the correct mounted mode" do
      mounted_api = nil
      mounted_api = @api[dev[0]]['mounted'] if @api_desc
      mounted_ohai = dev[1][:mounted]
      expect(mounted_ohai).to eql(mounted_api), "#{mounted_ohai}, #{mounted_api}, network_adapters, #{dev[0]}, mounted"
    end

    it "should not be a management card" do
      mgt_api = nil
      mgt_api = @api[dev[0]]['management'] if @api_desc
      mgt_ohai = dev[1][:management]
      expect(mgt_ohai).to eql(mgt_api), "#{mgt_ohai}, #{mgt_api}, network_adapters, #{dev[0]}, management"
    end

  end

end
