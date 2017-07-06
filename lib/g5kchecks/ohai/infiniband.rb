
require 'g5kchecks/utils/utils'

Ohai.plugin(:NetworkInfiniband) do

  provides "network/network_infiniband"
  depends "network"
  depends "hostname"

  collect_data do

    # Process ib interfaces
    network[:interfaces].select { |d,i| %w{ ib }.include?(i[:type]) }.each do |dev,iface|

      # Infiniband interfaces can't be management interfaces
      iface[:management] = false

      pci_infos = Utils.get_pci_infos("/sys/class/net/#{dev}/device/")
      iface[:vendor] = pci_infos[:vendor]
      iface[:model] = pci_infos[:device]

      # Get MAC address
      if File.exist?('/sys/class/infiniband/mthca0/ports')
        guid_prefix = "20:00:55:04:01:"
      elsif File.exist?('/sys/class/infiniband/mlx4_0/ports')
        guid_prefix = "20:00:55:00:41:"
        #FIXME: else ???
      end
      iface[:mac] = guid_prefix + File.read(File.join('/sys/class/net', dev, 'address')).chomp.split(':')[5..20].join(':')

      ca = ""
      stdout = Utils.shell_out("ibstat").stdout
      stdout.each_line do |line|
        if line =~ /^[[:blank:]]*CA '/
          ca = line.gsub("CA","")
          ca = ca.gsub(" ","")
          ca = ca.gsub("'","")
        end
        if line =~ /^[[:blank:]]*CA type/
          iface[:version] = line.chomp.split(": ").last
        end
      end

      if !ca.empty?
        num = "#{(iface[:number].to_i)+1}"
        stdout = Utils.shell_out("ibstat #{ca.chomp!} #{num}").stdout
        stdout.each_line do |line|
          if line =~ /^Rate/
            iface[:rate] = line.chomp.split(": ").last.to_i*1000000000
          end
          if line =~ /^State/
            iface[:enabled] = line.chomp.split(": ").last.eql?('Active') #or line.chomp.split(": ").last.eql?('Initializing')) See #7250 and #7244
          end
        end
      end

      # The interface is enabled iff state is 'Active' and /sys/class/infiniband/mlx4_0 exists.
      iface[:enabled] = iface[:enabled] && File.exist?('/sys/class/infiniband/mlx4_0')
      # Check ibX ip addressed only if interface is enabled
      iface[:check_ip] = iface[:enabled]

      ip = iface[:addresses].select{ |key,value| value[:family] == 'inet'}.to_a
      iface[:ip] = ip[0][0] if ip.size > 0
      ip6 = iface[:addresses].select{ |key,value| value[:family] == 'inet6'}.to_a
      iface[:ip6] = ip6[0][0] if ip6.size > 0
      iface[:mounted] = ( not iface[:ip].nil? )
      iface[:driver] = "mlx4_core"

      #Partition key management
      #Skip parent interface if there is a sub-interface
      #example: ib0.8100 based on physdev ib0
      if File.exist?("/sys/class/net/#{dev}/parent")
        parent = Utils.shell_out("cat /sys/class/net/#{dev}/parent").stdout rescue nil
        if !(parent.nil? || parent.empty?)
          #just delete the parent interface to skip testing it
          if dev.include?(parent)
            network[:interfaces].delete(parent)
          end
          # pkey = dev.sub(parent, '').sub('.', '') rescue nil
          # if !(pkey.nil? || pkey.empty?)
          #   network[:interfaces][parent][:pkey] = pkey
          #   #Skip checks of 
          #   network[:interfaces][parent][:skip] = true
          # end
        end
      end
    end
  end
end
