
describe "Network" do
  
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

  before(:all) do
    @system = RSpec.configuration.node.ohai_description[:network][:interfaces]
    @api = get_api_ifaces
  end

  ohai = RSpec.configuration.node.ohai_description[:network][:interfaces]
  ohai.select { |dev, iface|
    dev =~ /^en/ || %w{ ib eth myri }.include?(iface[:type])
  }.each do |dev,iface|

    #Skip interface if we decided to do so in ohai
    next if iface[:skip] == true

    it "should have the correct predictable name" do
      name_api = @api[dev]['name'] rescue ""
      name_ohai = iface[:name]
      Utils.test(name_ohai, name_api, "network_adapters/#{dev}/name") do |v_ohai, v_api, error_msg|
        expect(v_ohai).to eql(v_api), error_msg
      end
    end

    it "should be the correct interface type" do
      type_api = @api[dev]['interface'] rescue ""
      type_ohai = Utils.interface_type(iface[:type])
      Utils.test(type_ohai, type_api, "network_adapters/#{dev}/interface") do |v_ohai, v_api, error_msg|
        expect(v_ohai).to eql(v_api), error_msg
      end
    end

    #Only check IP address if initially mounted by system
    if iface[:check_ip] == true
      it "should have the correct IPv4" do
        ip_api = @api[dev]['ip'] rescue ""
        ip_ohai = iface[:ip]
        Utils.test(ip_ohai, ip_api, "network_adapters/#{dev}/ip") do |v_ohai, v_api, error_msg|
          expect(v_ohai).to eql(v_api), error_msg
        end
      end
    end

    it "should have the correct Driver" do
      driver_api = @api[dev]['driver'] rescue ""
      driver_ohai = iface[:driver]
      Utils.test(driver_ohai, driver_api, "network_adapters/#{dev}/driver") do |v_ohai, v_api, error_msg|
        expect(v_ohai).to eql(v_api), error_msg
      end
    end

    if dev =~ /ib/
      it "should have the correct guid" do
        mac_api = @api[dev]['guid'] rescue ""
        mac_ohai = iface[:mac].downcase
        Utils.test(mac_ohai, mac_api, "network_adapters/#{dev}/guid") do |v_ohai, v_api, error_msg|
          expect(v_ohai).to eql(v_api), error_msg
        end
      end
    else
      it "should have the correct Mac Address" do
        mac_api = @api[dev][:mac] rescue ""
        mac_ohai = iface[:mac].downcase
        Utils.test(mac_ohai, mac_api, "network_adapters/#{dev}/mac") do |v_ohai, v_api, error_msg|
          expect(v_ohai).to eql(v_api), error_msg
        end
      end
    end

    it "should have the correct Rate" do
      rate_api = @api[dev]['rate'].to_i rescue ""
      rate_ohai = iface[:rate].to_i rescue 0
      Utils.test(rate_ohai, rate_api, "network_adapters/#{dev}/rate") do |v_ohai, v_api, error_msg|
        expect(v_ohai).to eql(v_api), error_msg
      end
    end

    it "should have the correct firmware version" do
      ver_api = @api[dev]['firmware_version'].to_s rescue ""
      ver_ohai = iface[:firmware_version].to_s rescue ""
      Utils.test(ver_ohai, ver_api, "network_adapters/#{dev}/firmware_version") do |v_ohai, v_api, error_msg|
        expect(v_ohai).to eql(v_api), error_msg
      end
    end

    it "should have the correct model" do
      ven_api = @api[dev]['model'].downcase rescue ""
      ven_ohai = iface[:model].downcase rescue ""
      Utils.test(ven_ohai, ven_api, "network_adapters/#{dev}/model") do |v_ohai, v_api, error_msg|
        expect(v_ohai).to eql(v_api), error_msg
      end
    end
    
    it "should have the correct vendor" do
      ven_api = @api[dev]['vendor'].downcase rescue ""
      ven_ohai = iface['vendor'].downcase rescue ""
      Utils.test(ven_ohai, ven_api, "network_adapters/#{dev}/vendor") do |v_ohai, v_api, error_msg|
        expect(v_ohai).to eql(v_api), error_msg
      end
    end

    it "should have the correct mounted mode" do
      mounted_api = @api[dev]['mounted'] rescue false
      mounted_ohai = iface[:mounted]
      Utils.test(mounted_ohai, mounted_api, "network_adapters/#{dev}/mounted") do |v_ohai, v_api, error_msg|
        expect(v_ohai).to eql(v_api), error_msg
      end
    end

    it "should not be a management card" do
      mgt_api = @api[dev]['management'] rescue nil
      mgt_ohai = iface[:management]
      Utils.test(mgt_ohai, mgt_api, "network_adapters/#{dev}/management") do |v_ohai, v_api, error_msg|
        expect(v_ohai).to eql(v_api), error_msg
      end
    end
  end
end
