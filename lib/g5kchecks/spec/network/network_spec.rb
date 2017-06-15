
def get_api_ifaces
  ifaces = {}
  net_adapters = RSpec.configuration.node.api_description["network_adapters"]
  if net_adapters
    net_adapters.each{ |iface|
      ifaces[iface['device']] = iface
      #Easy transition to predictable names
      if !(iface['name'].nil? || iface['name'].empty?) && iface['device'] != iface['name']
        ifaces[iface['name']] = iface
      end
    }
  end
  ifaces
end

describe "Network" do

  before(:all) do
    @system = RSpec.configuration.node.ohai_description[:network][:interfaces]
    @api = get_api_ifaces
  end

  ohai = RSpec.configuration.node.ohai_description[:network][:interfaces]
  ohai.select { |dev, iface|
    dev =~ /^en/ || %w{ ib eth myri }.include?(iface[:type])
  }.each do |dev,iface|

    it "should have the correct predictable name" do
      name_api = @api[dev]['name'] rescue ""
      name_ohai = iface[:name]
      expect(name_ohai).to eql(name_api), "#{name_ohai}, #{name_api}, network_adapters, #{dev}, name"
    end

    it "should be the correct interface type" do
      type_api = @api[dev]['interface'] rescue ""
      type_ohai = Utils.interface_type(iface[:type])
      expect(type_ohai).to eql(type_api), "#{type_ohai}, #{type_api}, network_adapters, #{dev}, interface"
    end

    it "should have the correct IPv4" do
      ip_api = @api[dev]['ip'] rescue ""
      ip_ohai = iface[:ip]
      expect(ip_ohai).to eql(ip_api), "#{ip_ohai}, #{ip_api}, network_adapters, #{dev}, ip"
    end

    # Disabled ipv6 test: g5kchecks sets interfaces up, so IPv6 Stateless Address Autoconfiguration assigns
    # addresses to interfaces, which are not garanteed to be stable and derived from mac address,
    # which we already check.
    # it "should have the correct IPv6" do
    #   ip6_api = @api[dev]['ip6'] rescue ""
    #   ip6_ohai = iface[:ip6]
    #   expect(ip6_ohai).to eql(ip6_api), "#{ip6_ohai}, #{ip6_api}, network_adapters, #{dev}, ip6"
    # end

    it "should have the correct Driver" do
      driver_api = @api[dev]['driver'] rescue ""
      driver_ohai = iface[:driver]
      expect(driver_ohai).to eql(driver_api), "#{driver_ohai}, #{driver_api}, network_adapters, #{dev}, driver"
    end

    if dev =~ /ib/
      it "should have the correct guid" do
        mac_api = @api[dev]['guid'] rescue ""
        mac_ohai = iface[:mac].downcase
        expect(mac_ohai).to eql(mac_api), "#{mac_ohai}, #{mac_api}, network_adapters, #{dev}, guid"
      end
    else
      it "should have the correct Mac Address" do
        mac_api = @api[dev]['mac'] rescue ""
        mac_ohai = iface[:mac].downcase
        expect(mac_ohai).to eql(mac_api), "#{mac_ohai}, #{mac_api}, network_adapters, #{dev}, mac"
      end
    end

    it "should have the correct Rate" do
      rate_api = @api[dev]['rate'].to_i rescue ""
      rate_ohai = iface[:rate].to_i
      expect(rate_ohai).to eql(rate_api), "#{rate_ohai}, #{rate_api}, network_adapters, #{dev}, rate"
    end

    it "should have the correct version" do
      ver_api = @api[dev]['version'] rescue ""
      ver_ohai = iface[:version]
      expect(ver_ohai).to eql(ver_api), "#{ver_ohai}, #{ver_api}, network_adapters, #{dev}, version"
    end

    it "should have the correct vendor" do
      ven_api = @api[dev]['vendor'] rescue ""
      ven_ohai = iface['vendor']
      expect(ven_ohai).to eql(ven_api), "#{ven_ohai}, #{ven_api}, network_adapters, #{dev}, vendor"
    end

    it "should have the correct mounted mode" do
      mounted_api = @api[dev]['mounted'] rescue false
      mounted_ohai = iface[:mounted]
      expect(mounted_ohai).to eql(mounted_api), "#{mounted_ohai}, #{mounted_api}, network_adapters, #{dev}, mounted"
    end

    it "should not be a management card" do
      mgt_api = @api[dev]['management'] rescue nil
      mgt_ohai = iface[:management]
      expect(mgt_ohai).to eql(mgt_api), "#{mgt_ohai}, #{mgt_api}, network_adapters, #{dev}, management"
    end
  end
end
