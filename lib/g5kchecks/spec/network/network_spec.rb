# frozen_string_literal: true

describe 'Network' do
  # Get Interfaces from API
  ifaces = {}
  net_adapters = RSpec.configuration.node.api_description['network_adapters']
  # Easy transition to predictable names
  net_adapters&.each do |iface|
    ifaces[iface['device']] = iface
    # Easy transition to predictable names
    ifaces[iface['name']] = iface if !(iface['name'].nil? || iface['name'].empty?) && iface['device'] != iface['name']
  end

  ohai = RSpec.configuration.node.ohai_description[:network][:interfaces]
  ohai_ifaces = ohai.select do |dev, iface|
    dev =~ /^en/ || %w[eth myri].include?(iface[:type]) || %w[infiniband].include?(iface[:encapsulation])
  end

  it 'should not lack any of the interfaces from the API (except interfaces with driver = "n/a")' do
    expect(
      net_adapters.reject do |e|
          !(e['mountable']) ||
          e['driver'] == 'n/a' ||
          ohai_ifaces.include?(e['name']) ||
          ohai_ifaces.include?(e['device'])
      end
    ).to be_empty
  end

  it 'should have the correct number of network interfaces (excluding management interfaces and interfaces whose drivers = "n/a")' do
    # 'true' in fourth parameter means that we do not add the result to the API
    Utils.test(
      ohai_ifaces.length,
      net_adapters.count { |e| !e['management'] && e['driver'] != 'n/a' },
      'network_adapters/length',
      true
    ) do |v_ohai, v_api, error_msg|
      expect(v_ohai).to eql(v_api), error_msg
    end
  end

  ohai_ifaces.each do |dev, iface|
    # Skip interface if we decided to do so in ohai
    next if iface[:skip] == true

    api = ifaces[dev] || {} # use an empty hash in API mode

    it 'should have the correct predictable name' do
      name_api = api['name']
      name_ohai = iface[:name]
      Utils.test(name_ohai, name_api, "network_adapters/#{dev}/name") do |v_ohai, v_api, error_msg|
        expect(v_ohai).to eql(v_api), error_msg
      end
    end

    it 'should be the correct interface type' do
      type_api = api['interface']
      type_ohai = Utils.interface_type(iface)
      Utils.test(type_ohai, type_api, "network_adapters/#{dev}/interface") do |v_ohai, v_api, error_msg|
        expect(v_ohai).to eql(v_api), error_msg
      end
    end

    # Only check IP address if initially mounted by system
    if iface[:mounted]
      it 'should have the correct IPv4' do
        ip_api = api['ip']
        ip_ohai = iface[:ip]
        Utils.test(ip_ohai, ip_api, "network_adapters/#{dev}/ip") do |v_ohai, v_api, error_msg|
          expect(v_ohai).to eql(v_api), error_msg
        end
      end
    end

    it 'should have the correct Driver' do
      driver_api = api['driver']
      driver_ohai = iface[:driver]
      Utils.test(driver_ohai, driver_api, "network_adapters/#{dev}/driver") do |v_ohai, v_api, error_msg|
        expect(v_ohai).to eql(v_api), error_msg
      end
    end

    it 'should have the correct Mac Address' do
      mac_api = api['mac']
      mac_ohai = iface[:mac].downcase
      Utils.test(mac_ohai, mac_api, "network_adapters/#{dev}/mac") do |v_ohai, v_api, error_msg|
        expect(v_ohai).to eql(v_api), error_msg
      end
    end

    # Omni-Path/Infiniband specific
    if /ib/.match?(dev)
      it 'should have the correct guid' do
        mac_api = api['guid']
        mac_ohai = iface[:guid].downcase
        Utils.test(mac_ohai, mac_api, "network_adapters/#{dev}/guid") do |v_ohai, v_api, error_msg|
          expect(v_ohai).to eql(v_api), error_msg
        end
      end

      it 'should be enabled (active)' do
        enabled_api = api['enabled']
        enabled_ohai = iface['enabled']
        Utils.test(enabled_ohai, enabled_api, "network_adapters/#{dev}/enabled") do |v_ohai, v_api, error_msg|
          expect(v_ohai).to eql(v_api), error_msg
        end
      end
    end

    it 'should have the correct Rate' do
      rate_api = api['rate'].to_i
      rate_ohai = iface[:rate].to_i
      Utils.test(rate_ohai, rate_api, "network_adapters/#{dev}/rate") do |v_ohai, v_api, error_msg|
        expect(v_ohai).to eql(v_api), error_msg
      end
    end

    it 'should have the correct firmware version' do
      ver_api = api['firmware_version'].to_s
      ver_ohai = iface[:firmware_version].to_s
      Utils.test(ver_ohai, ver_api, "network_adapters/#{dev}/firmware_version") do |v_ohai, v_api, error_msg|
        expect(v_ohai).to eql(v_api), error_msg
      end
    end

    it 'should have the correct model' do
      ven_api = api['model']
      ven_ohai = iface[:model]
      Utils.test(ven_ohai, ven_api, "network_adapters/#{dev}/model") do |v_ohai, v_api, error_msg|
        expect(v_ohai).to eql(v_api), error_msg
      end
    end

    it 'should have the correct vendor' do
      ven_api = api['vendor']
      ven_ohai = iface['vendor']
      Utils.test(ven_ohai, ven_api, "network_adapters/#{dev}/vendor") do |v_ohai, v_api, error_msg|
        expect(v_ohai).to eql(v_api), error_msg
      end
    end

    it 'should have the correct mounted mode' do
      mounted_api = api['mounted']
      mounted_ohai = iface[:mounted]
      Utils.test(mounted_ohai, mounted_api, "network_adapters/#{dev}/mounted") do |v_ohai, v_api, error_msg|
        expect(v_ohai).to eql(v_api), error_msg
      end
    end

    it 'should not be a management card' do
      mgt_api = api['management']
      mgt_ohai = iface[:management]
      Utils.test(mgt_ohai, mgt_api, "network_adapters/#{dev}/management") do |v_ohai, v_api, error_msg|
        expect(v_ohai).to eql(v_api), error_msg
      end
    end

    it 'should have SR-IOV correctly detected' do
      sriov_api = api['sriov']
      sriov_ohai = iface[:sriov]
      Utils.test(sriov_ohai, sriov_api, "network_adapters/#{dev}/sriov") do |v_ohai, v_api, error_msg|
        expect(v_ohai).to eql(v_api), error_msg
      end
    end

    it 'should have correct number of SR-IOV totalvfs' do
      sriov_totalvfs_api = api['sriov_totalvfs']
      sriov_totalvfs_ohai = iface[:sriov_totalvfs]
      Utils.test(sriov_totalvfs_ohai, sriov_totalvfs_api, "network_adapters/#{dev}/sriov_totalvfs") do |v_ohai, v_api, error_msg|
        expect(v_ohai).to eql(v_api), error_msg
      end
    end
  end
end
