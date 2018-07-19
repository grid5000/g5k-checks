
describe "Network" do

  # Get Interfaces from API
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

  ohai = RSpec.configuration.node.ohai_description[:network][:interfaces]
  ohai_ifaces = ohai.select { |dev, iface|
    dev =~ /^en/ || %w{ ib eth myri }.include?(iface[:type])
  }

  it "should not lack any of the interfaces from the API" do
    expect(net_adapters.reject { |e| (not e['mountable']) or ohai_ifaces.include?(e['name']) or ohai_ifaces.include?(e['name']) }).to be_empty
  end

  ohai_ifaces.each do |dev,iface|
    #Skip interface if we decided to do so in ohai
    next if iface[:skip] == true

    api = ifaces[dev] || {} # use an empty hash in API mode

    it "should have the correct predictable name" do
      name_api = api['name']
      name_ohai = iface[:name]
      Utils.test(name_ohai, name_api, "network_adapters/#{dev}/name") do |v_ohai, v_api, error_msg|
        expect(v_ohai).to eql(v_api), error_msg
      end
    end

    it "should be the correct interface type" do
      type_api = api['interface']
      type_ohai = Utils.interface_type(iface)
      Utils.test(type_ohai, type_api, "network_adapters/#{dev}/interface") do |v_ohai, v_api, error_msg|
        expect(v_ohai).to eql(v_api), error_msg
      end
    end

    #Only check IP address if initially mounted by system
    if iface[:check_ip] == true
      it "should have the correct IPv4" do
        ip_api = api['ip']
        ip_ohai = iface[:ip]
        Utils.test(ip_ohai, ip_api, "network_adapters/#{dev}/ip") do |v_ohai, v_api, error_msg|
          expect(v_ohai).to eql(v_api), error_msg
        end
      end
    end

    it "should have the correct Driver" do
      driver_api = api['driver']
      driver_ohai = iface[:driver]
      Utils.test(driver_ohai, driver_api, "network_adapters/#{dev}/driver") do |v_ohai, v_api, error_msg|
        expect(v_ohai).to eql(v_api), error_msg
      end
    end

    it "should have the correct Mac Address" do
      mac_api = api['mac']
      mac_ohai = iface[:mac].downcase
      Utils.test(mac_ohai, mac_api, "network_adapters/#{dev}/mac") do |v_ohai, v_api, error_msg|
        expect(v_ohai).to eql(v_api), error_msg
      end
    end

    #Omni-Path/Infiniband specific
    if dev =~ /ib/
      it "should have the correct guid" do
        mac_api = api['guid']
        mac_ohai = iface[:guid].downcase
        Utils.test(mac_ohai, mac_api, "network_adapters/#{dev}/guid") do |v_ohai, v_api, error_msg|
          expect(v_ohai).to eql(v_api), error_msg
        end
      end
    end

    it "should have the correct Rate" do
      rate_api = api['rate'].to_i
      rate_ohai = iface[:rate].to_i
      Utils.test(rate_ohai, rate_api, "network_adapters/#{dev}/rate") do |v_ohai, v_api, error_msg|
        expect(v_ohai).to eql(v_api), error_msg
      end
    end

    it "should have the correct firmware version" do
      ver_api = api['firmware_version'].to_s
      ver_ohai = iface[:firmware_version].to_s
      Utils.test(ver_ohai, ver_api, "network_adapters/#{dev}/firmware_version") do |v_ohai, v_api, error_msg|
        expect(v_ohai).to eql(v_api), error_msg
      end
    end

    it "should have the correct model" do
      ven_api = api['model']
      ven_ohai = iface[:model]
      Utils.test(ven_ohai, ven_api, "network_adapters/#{dev}/model") do |v_ohai, v_api, error_msg|
        expect(v_ohai).to eql(v_api), error_msg
      end
    end

    it "should have the correct vendor" do
      ven_api = api['vendor']
      ven_ohai = iface['vendor']
      Utils.test(ven_ohai, ven_api, "network_adapters/#{dev}/vendor") do |v_ohai, v_api, error_msg|
        expect(v_ohai).to eql(v_api), error_msg
      end
    end

    it "should have the correct mounted mode" do
      mounted_api = api['mounted']
      mounted_ohai = iface[:mounted]
      Utils.test(mounted_ohai, mounted_api, "network_adapters/#{dev}/mounted") do |v_ohai, v_api, error_msg|
        expect(v_ohai).to eql(v_api), error_msg
      end
    end

    it "should not be a management card" do
      mgt_api = api['management']
      mgt_ohai = iface[:management]
      Utils.test(mgt_ohai, mgt_api, "network_adapters/#{dev}/management") do |v_ohai, v_api, error_msg|
        expect(v_ohai).to eql(v_api), error_msg
      end
    end
  end
end
