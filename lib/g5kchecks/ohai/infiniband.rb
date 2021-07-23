# frozen_string_literal: true

require 'g5kchecks/utils/utils'
require 'peach'

Ohai.plugin(:NetworkInfiniband) do
  provides 'network/network_infiniband'
  depends 'network'
  depends 'hostname'

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
    ibstat_interfaces = Utils.shell_out('ibstat -l').stdout.chomp.gsub(' ', '').gsub("'", '').split
    guid_interfaces = {}

    ibstat_interfaces.each do |i|
      port = ''
      Utils.shell_out("ibstat #{i}").stdout.each_line do |line|
        port = Regexp.last_match(1) if line =~ /Port\s(\d+)/
        guid_interfaces[Regexp.last_match(1)] = { port: port, interface: i } if line =~ /Port\sGUID:\s(.*)$/
      end
    end

    # Process ib interfaces
    # note: encapsulation='infiniband' for OPA interfaces as well
    network[:interfaces].select { |_d, i| %w[infiniband].include?(i[:encapsulation]) }.peach do |dev, iface|
      # Infiniband interfaces can't be management interfaces
      iface[:management] = false

      # Forcing predictable name to device
      iface[:name] = dev

      pci_infos = Utils.get_pci_infos("/sys/class/net/#{dev}/device/")
      iface[:vendor] = pci_infos[:vendor]
      iface[:model] = pci_infos[:device]
      iface[:driver] = pci_infos.has_key?(:driver) ? pci_infos[:driver] : nil

      # Get MAC address
      iface[:mac] = iface[:addresses].select { |_key, value| value[:family] == 'lladdr' }.keys[0]
      ## Only keep last 8 bytes, as prefix depends on QPN and SM (see RFC4391)
      iface[:mac] = iface[:mac].split(":").last(8).join(":")

      # Get Port UID from MAC address
      port_guid = "0x#{iface[:mac].split(':').join.downcase}"

      # Get the interface name and the port number
      ibstat_iface_name = guid_interfaces[port_guid][:interface]
      ibstat_port_num = guid_interfaces[port_guid][:port]

      # TODO: when Debian 11 is pushed as the standard environment, 'hfi1' and 'mlx'
      # matches will be removable
      if ibstat_iface_name =~ /(hfi1|opa)/
        iface[:interface] = 'Omni-Path'
      elsif ibstat_iface_name =~ /(mlx(\d+)|ib)/
        iface[:interface] = 'InfiniBand'
      end

      # Channel adapter
      stdout = Utils.shell_out("ibstat #{ibstat_iface_name}").stdout
      stdout.each_line do |line|
        iface[:firmware_version] = line.chomp.split(': ')[1] if line =~ /^[[:blank:]]*Firmware version/
      end

      stdout = Utils.shell_out("ibstat #{ibstat_iface_name} #{ibstat_port_num}").stdout
      stdout.each_line do |line|
        iface[:guid] = line.chomp.split(': ').last if line =~ /Port[[:blank:]]GUID/
        iface[:rate] = line.chomp.split(': ').last.to_i * 1_000_000_000 if line =~ /Rate/
        if line =~ /State/
          iface[:enabled] = line.chomp.split(': ').last.eql?('Active') # or line.chomp.split(": ").last.eql?('Initializing')) See #7250 and #7244
        end
      end

      # Check ibX ip addressed only if interface is enabled
      iface[:check_ip] = iface[:enabled]

      ip = iface[:addresses].select { |_key, value| value[:family] == 'inet' }.to_a
      iface[:ip] = ip[0][0] unless ip.empty?
      ip6 = iface[:addresses].select { |_key, value| value[:family] == 'inet6' }.to_a
      iface[:ip6] = ip6[0][0] unless ip6.empty?
      iface[:mounted] = !iface[:ip].nil?
    end
  end
end
