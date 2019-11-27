
require 'g5kchecks/utils/utils'

Ohai.plugin(:NetworkInfiniband) do

  provides "network/network_infiniband"
  depends "network"
  depends "hostname"

  # def get_mac_address(guid, dev)
  #   mac = File.read(File.join('/sys/class/net', dev, 'address'))
  #   if guid == ""
  #     return mac.chomp
  #   else
  #     return guid + mac.chomp.split(':')[5..20].join(':')
  #   end
  # end
  collect_data do
    # Get interfaces from ibstat and put them inside a Hash so we can get
    # them by the guid
    ibstat_interfaces = Utils.shell_out("ibstat -l").stdout.chomp.gsub(" ","").gsub("'","").split
    guid_interfaces = Hash.new

    ibstat_interfaces.each do |i|
      port = ''
      Utils.shell_out("ibstat #{i}").stdout.each_line do |line|
        if line =~ /Port\s(\d+)/
          port = $1
        end
        if line =~ /Port\sGUID:\s(.*)$/
          guid_interfaces[$1] = { port: port, interface: i }
        end
      end
    end

    # Process ib interfaces
    # note: encapsulation='infiniband' for OPA interfaces as well
    network[:interfaces].select { |d,i| %w{ infiniband }.include?(i[:encapsulation]) }.each do |dev,iface|

      # Infiniband interfaces can't be management interfaces
      iface[:management] = false

      # Forcing predictable name to device
      iface[:name] = dev

      pci_infos = Utils.get_pci_infos("/sys/class/net/#{dev}/device/")
      iface[:vendor] = pci_infos[:vendor]
      iface[:model] = pci_infos[:device]

      # Get MAC address
      iface[:mac] = iface[:addresses].select{|key,value| value[:family] == 'lladdr'}.keys[0]

      # Get Port UID from MAC address
      port_guid = "0x#{iface[:mac].split(':')[12..19].join.downcase}"

      # Get the interface name and the port number
      ibstat_iface_name = guid_interfaces[port_guid][:interface]
      ibstat_port_num = guid_interfaces[port_guid][:port]

      if ibstat_iface_name =~ /hfi1/
        iface[:interface] = "Omni-Path"
        iface[:driver] = "hfi1"
      elsif ibstat_iface_name =~ /mthca/
        iface[:interface] = "InfiniBand"
        iface[:driver] = "mthca" #Might never be used
      elsif ibstat_iface_name =~ /mlx(\d+)/
        iface[:interface] = "InfiniBand"
        iface[:driver] = "mlx#{$1}_core"
      end

      #Channel adapter
      stdout = Utils.shell_out("ibstat #{ibstat_iface_name}").stdout
      stdout.each_line do |line|
        if line =~ /^[[:blank:]]*Firmware version/
          iface[:firmware_version] = line.chomp.split(": ")[1]
        end
      end

      stdout = Utils.shell_out("ibstat #{ibstat_iface_name} #{ibstat_port_num}").stdout
      stdout.each_line do |line|
        if line =~ /Port[[:blank:]]GUID/
          iface[:guid] = line.chomp.split(": ").last
        end
        if line =~ /Rate/
          iface[:rate] = line.chomp.split(": ").last.to_i * 1000000000
        end
        if line =~ /State/
          iface[:enabled] = line.chomp.split(": ").last.eql?('Active') #or line.chomp.split(": ").last.eql?('Initializing')) See #7250 and #7244
        end
      end

      # Check ibX ip addressed only if interface is enabled
      iface[:check_ip] = iface[:enabled]

      ip = iface[:addresses].select{ |key,value| value[:family] == 'inet'}.to_a
      iface[:ip] = ip[0][0] if ip.size > 0
      ip6 = iface[:addresses].select{ |key,value| value[:family] == 'inet6'}.to_a
      iface[:ip6] = ip6[0][0] if ip6.size > 0
      iface[:mounted] = ( not iface[:ip].nil? )
    end
  end
end
