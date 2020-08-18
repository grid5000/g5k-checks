# frozen_string_literal: true

require 'g5kchecks/utils/utils'
require 'peach'

Ohai.plugin(:NetworkAdapters) do
  provides 'network/network_adapters'
  depends 'network'
  depends 'hostname'

  collect_data do
    interfaces = network[:interfaces]

    @br_iface = nil

    interfaces.select { |_d, i| i[:type] == 'br' }.each do |dev, iface|
      @br_iface = dev
      iface[:brif] = []

      # Add bridged interfaces information to bridge interface, if any
      stdout = Utils.shell_out("ls -1 /sys/devices/virtual/net/#{dev}/brif/").stdout
      stdout.each_line do |line|
        iface[:brif] << line.chomp
      end
    end

    # Process all but bridge, infiniband and loopback
    interfaces.reject { |d, i| %w[ib br].include?(i[:type]) || d == 'lo' }.each do |dev, iface|
      # Likely not a management interface if it is accessible from the OS.
      iface[:management] = false

      # Get MAC address
      iface[:mac] = iface[:addresses].select { |_key, value| value[:family] == 'lladdr' }.keys[0]

      # Get the predictable name of the interface
      iface[:name] = Utils.interface_predictable_name(dev)

      # true if predictable names are in use
      iface[:use_predictable_name] = iface[:name] == dev

      ifaceStatus = Utils.interface_operstate(dev)
      ethtool = Utils.interface_ethtool(dev)
      if ifaceStatus != 'up'
        # Bring interface up to allow correct rate/enabled report
        Utils.shell_out("/sbin/ip link set dev #{dev} up")
      end
      now = Time.now.to_i
      timeout = if ifaceStatus == 'down'
                  15
                else
                  # If interface was already up, reduce timeout
                  5
                end

      # Wait for link negociation after setting iface up
      ethtool_infos = {}
      while Time.now.to_i < now + timeout
        sleep(1)
        status = Utils.interface_operstate(dev)
        # Make probing quicker if interface stays down
        timeout -= 0.5 if status == 'down'
        # Get infos only if interesting or is last run
        next unless status != 'down' || Time.now.to_i >= now + timeout

        ethtool_infos = Utils.interface_ethtool(dev)
        # exit early if rate changed
        if !ethtool_infos[:rate].nil? &&
           (ethtool_infos[:rate] != ethtool[:rate] || ethtool_infos[:rate].to_i != 0)
          break
        end
      end
      iface[:rate] = ethtool_infos[:rate]
      iface[:driver] = ethtool_infos[:driver]
      iface[:firmware_version] = ethtool_infos[:firmware_version]

      pci_infos = Utils.get_pci_infos("/sys/class/net/#{dev}/device/")
      iface[:vendor] = pci_infos[:vendor]
      iface[:model] = pci_infos[:device]

      ip = iface[:addresses].select { |_key, value| value[:family] == 'inet' }.to_a
      iface[:ip] = ip[0][0] unless ip.empty?
      ip6 = iface[:addresses].select { |_key, value| value[:family] == 'inet6' }.to_a
      iface[:ip6] = ip6[0][0] unless ip6.empty?

      # Get the addresses from bridge interface if possible
      if iface[:ip].nil? && !@br_iface.nil? && interfaces[@br_iface][:brif].include?(dev)
        ip = interfaces[@br_iface][:addresses].select { |_key, value| value[:family] == 'inet' }.to_a
        iface[:ip] = ip[0][0] unless ip.empty?
        ip6 = interfaces[@br_iface][:addresses].select { |_key, value| value[:family] == 'inet6' }.to_a
        iface[:ip6] = ip6[0][0] unless ip6.empty?
      end
      iface[:mounted] = !iface[:ip].nil?
    end

    # Process management interface
    # Get MAC address from ipmitool if possible
    if File.exist?('/usr/bin/ipmitool')
      try = 0
      shell_out = nil
      begin
        try += 1
        shell_out = Utils.shell_out('/usr/bin/ipmitool lan print')
        raise 'ipmitool returned an error' if shell_out.stderr.chomp != ''
      rescue StandardError
        if try < 5
          sleep 0.5
          retry
        else
          raise 'Failed to get IP/MAC for BMC (ipmitool error)'
        end
      end
      shell_out.stdout.each_line do |line|
        if line =~ /^[[:blank:]]*MAC Address/
          interfaces['bmc'] ||= {}
          interfaces['bmc'][:mac] = line.chomp.split(': ').last
        end
        if line =~ /^[[:blank:]]*IP Address/
          interfaces['bmc'] ||= {}
          interfaces['bmc'][:ip] = line.chomp.split(': ').last
        end
      end
      interfaces['bmc'][:management] = true if interfaces['bmc']
    end
  end
end
