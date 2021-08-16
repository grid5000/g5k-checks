# frozen_string_literal: true

require 'g5kchecks/utils/utils'
require 'peach'

Ohai.plugin(:NetworkAdapters) do
  provides 'network/network_adapters'
  depends 'g5k'
  depends 'network'
  depends 'hostname'
  depends 'chassis'

  collect_data do
    interfaces = network[:interfaces]

    threads = []

    threads << Thread.new do
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
      interfaces_to_process = interfaces.reject { |d, i| %w[ib br].include?(i[:type]) || d == 'lo' }

      # First, we put the interfaces up
      was_down = {}
      interfaces_to_process.peach do |dev, _|
        if Utils.interface_operstate(dev) != 'up'
          # Bring interface up to allow correct rate/enabled report
          Utils.shell_out("/sbin/ip link set dev #{dev} up")
          was_down[dev] = true
        else
          was_down[dev] = false
        end
      end

      interfaces_to_process.peach do |dev, iface|
        # Likely not a management interface if it is accessible from the OS.
        iface[:management] = false
        # Get MAC address
        iface[:mac] = iface[:addresses].select { |_key, value| value[:family] == 'lladdr' }.keys[0]

        # Get the predictable name of the interface
        iface[:name] = Utils.interface_predictable_name(dev)

        # true if predictable names are in use
        iface[:use_predictable_name] = iface[:name] == dev

        api_desc = g5k.dig('local_api_description', 'network_adapters')&.select { |i| i['name'] == dev }&.first
        ethtool_infos = Utils.interface_ethtool(dev)

        if api_desc&.dig('mountable') || api_desc.nil?
          now = Time.now.to_i
          timeout = if Utils.interface_operstate(dev) == 'down'
                      25
                    else
                      # If interface was already up, reduce timeout
                      5
                    end

          # Wait for link negociation after setting iface up
          ethtool = Utils.interface_ethtool(dev)
          while Time.now.to_i < now + timeout
            sleep(0.5)
            status = Utils.interface_operstate(dev)
            # Get infos only if interesting or is last run
            next unless status != 'down' || Time.now.to_i >= now + timeout

            ethtool_infos = Utils.interface_ethtool(dev)
            # exit early if rate changed
            if !ethtool_infos[:rate].nil? &&
                (ethtool_infos[:rate] != ethtool[:rate] || ethtool_infos[:rate].to_i != 0)
              break
            end
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

        # Detect presence of SR-IOV
        if File.exist?("/sys/class/net/#{dev}/device/sriov_totalvfs")
          iface[:sriov] = true
          iface[:sriov_totalvfs] = Utils.fileread("/sys/class/net/#{dev}/device/sriov_totalvfs").to_i
        else
          iface[:sriov] = false
          iface[:sriov_totalvfs] = 0
        end
      end

      # We put down the interfaces which were down before processing
      was_down.peach do |dev, status|
        if status
          Utils.shell_out("/sbin/ip link set dev #{dev} down")
          Utils.shell_out("/sbin/ip address flush dev #{dev}")
          Utils.shell_out("/sbin/ip route flush dev #{dev}")
          Utils.shell_out("/sbin/ip -6 route flush dev #{dev}")
        end
      end
    end

    # Process management interface
    # Get MAC address from ipmitool if possible
    threads << Thread.new do
      shell_out = Utils.ipmitool_shell_out('lan print', chassis)

      shell_out.stdout.each_line do |line|
        if /^[[:blank:]]*MAC Address/.match?(line)
          interfaces['bmc'] ||= {}
          interfaces['bmc'][:mac] = line.chomp.split(': ').last
        end
        if /^[[:blank:]]*IP Address/.match?(line)
          interfaces['bmc'] ||= {}
          interfaces['bmc'][:ip] = line.chomp.split(': ').last
        end
      end
      interfaces['bmc'][:management] = true if interfaces['bmc']
    end

    threads.each(&:join)
  end
end
