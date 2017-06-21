
require 'g5kchecks/utils/utils'

Ohai.plugin(:NetworkAdapters) do

  provides "network/network_adapters"
  depends "network"
  depends "hostname"

  collect_data do

    interfaces = network[:interfaces]

    @br_iface = nil

    interfaces.select{ |d,i| i[:type] == 'br'}.each { |dev, iface|

      @br_iface = dev
      iface[:brif] = []

      #Add bridged interfaces information to bridge interface, if any
      stdout = Utils.shell_out("ls -1 /sys/devices/virtual/net/#{dev}/brif/").stdout
      stdout.each_line do |line|
        iface[:brif] << line.chomp()
      end
    }

    # Process all but infiniband and loopback
    interfaces.reject{ |d,i| %w{ ib br }.include?(i[:type]) || d == "lo" }.each do |dev, iface|

      # Likely not a management interface if it is accessible from the OS.
      iface[:management] = false

      # Get MAC address
      iface[:mac] = iface[:addresses].select{|key,value| value[:family] == 'lladdr'}.keys[0]

      #Get the predictable name of the interface
      iface[:name] = Utils.shell_out("/sbin/udevadm test 2>&1 /sys/class/net/#{dev} | grep ID_NET_NAME_PATH | cut -d'=' -f2").stdout.chomp() rescue nil

      #true if predictable names are in use
      iface[:use_predictable_name] = iface[:name] == dev

      ifaceStatus = Utils.interface_operstate(dev)
      ethtool = Utils.interface_ethtool(dev)
      if (ifaceStatus != "up")
        #don't check IPs for initialy down interfaces
        iface[:check_ip] = false
        #Bring interface up to allow correct rate/enabled report
        Utils.shell_out("/sbin/ip link set dev #{dev} up")
      else
        iface[:check_ip] = true
      end
      now = Time.now.to_i
      if ifaceStatus == "down"
        timeout = 10
      else
        #If interface was already up, reduce timeout
        timeout = 5
      end

      #Wait for link negociation after setting iface up
      ethtool_infos = {}
      while Time.now.to_i < now + timeout
        sleep(1)
        status = Utils.interface_operstate(dev)
        #Make probing quicker if interface stays down
        if status == "down"
          timeout = timeout - 1
        end
        #Get infos only if interesting or is last run
        if status != "down" || Time.now.to_i >= now + timeout
          ethtool_infos = Utils.interface_ethtool(dev)
          #exit early if rate changed
          if (!ethtool_infos[:rate].nil? &&
              (ethtool_infos[:rate] != ethtool[:rate] || ethtool_infos[:rate].to_i != 0))
            break
          end
        end
      end
      iface[:rate] = ethtool_infos[:rate]
      iface[:driver] = ethtool_infos[:driver]
      iface[:version] = ethtool_infos[:version]

      iface[:vendor] = Utils.get_pci_vendor("/sys/class/net/#{dev}/device/vendor")
      if !iface[:vendor]
        iface[:vendor] = Utils.get_pci_vendor("/sys/class/net/#{dev}/device/subsystem_vendor")
      end

      ip = iface[:addresses].select{|key,value| value[:family] == 'inet'}.to_a
      iface[:ip] = ip[0][0] if ip.size > 0
      ip6 = iface[:addresses].select{|key,value| value[:family] == 'inet6'}.to_a
      iface[:ip6] = ip6[0][0] if ip6.size > 0

      #Get the addresses from bridge interface if possible
      if iface[:ip].nil? && @br_iface != nil && interfaces[@br_iface][:brif].include?(dev)
        ip = interfaces[@br_iface][:addresses].select{|key,value| value[:family] == 'inet'}.to_a
        iface[:ip] = ip[0][0] if ip.size > 0
        ip6 = interfaces[@br_iface][:addresses].select{|key,value| value[:family] == 'inet6'}.to_a
        iface[:ip6] = ip6[0][0] if ip6.size > 0
      end
      iface[:mounted] = ( not iface[:ip].nil? )
    end

    # Process management interface
    # Get MAC address from ipmitool if possible
    if File.exist?('/usr/bin/ipmitool')
      stdout = Utils.shell_out("/usr/bin/ipmitool lan print").stdout
      stdout.each_line do |line|
        if line =~ /^[[:blank:]]*MAC Address/
          interfaces["bmc"] ||= {}
          interfaces["bmc"][:mac] = line.chomp.split(": ").last
        end
        if line =~ /^[[:blank:]]*IP Address/
          interfaces["bmc"] ||= {}
          interfaces["bmc"][:ip] = line.chomp.split(": ").last
        end
      end
      interfaces["bmc"][:management] = true if interfaces["bmc"]
    end
  end
end
