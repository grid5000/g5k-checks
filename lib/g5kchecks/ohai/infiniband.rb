
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

    # Process ib interfaces
    network[:interfaces].select { |d,i| %w{ ib }.include?(i[:type]) }.each do |dev,iface|

      # Infiniband interfaces can't be management interfaces
      iface[:management] = false

      # Forcing predictable name to device
      iface[:name] = dev

      pci_infos = Utils.get_pci_infos("/sys/class/net/#{dev}/device/")
      iface[:vendor] = pci_infos[:vendor]
      iface[:model] = pci_infos[:device]

      # Get MAC address
      iface[:mac] = iface[:addresses].select{|key,value| value[:family] == 'lladdr'}.keys[0]

      if File.exist?('/sys/class/infiniband/hfi1_0/ports')
        iface[:interface] = "Omni-Path"
        iface[:driver] = "hfi1"
      elsif File.exist?('/sys/class/infiniband/mthca0/ports')
        iface[:interface] = "Infiniband"
        iface[:driver] = "mthca" #Might never be used
      elsif File.exist?('/sys/class/infiniband/mlx4_0/ports')
        iface[:interface] = "Infiniband"
        iface[:driver] = "mlx4_core"
      end

      #Channel adapter
      ca = Utils.shell_out("ibstat -l").stdout.chomp.gsub(" ","").gsub("'","") rescue ""
      stdout = Utils.shell_out("ibstat").stdout
      stdout.each_line do |line|
        if line =~ /^[[:blank:]]*Firmware version/
          iface[:firmware_version] = line.chomp.split(": ")[1]
        end
      end

      if !ca.empty?
        num = "#{(iface[:number].to_i)+1}"
        stdout = Utils.shell_out("ibstat #{ca.chomp} #{num}").stdout
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
      end

      # The interface is enabled if state is 'Active' and
      # /sys/class/infiniband/<mlx4_0|hfi1_0> exists.
      iface[:enabled] = iface[:enabled] && (
        File.exist?('/sys/class/infiniband/mlx4_0') ||
        File.exist?('/sys/class/infiniband/hfi1_0'))
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
