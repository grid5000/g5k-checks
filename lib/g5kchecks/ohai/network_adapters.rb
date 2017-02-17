require 'resolv'

provides "network/network_adapters"
require_plugin("network")
require_plugin("hostname")


interfaces = network[:interfaces]

# Process only eno, eth, and myri interfaces first
interfaces.select { |d,i| %w{ eno eth myri }.include?(i[:type]) }.each do |dev,iface|
  # It is likely that an interface is not the management interface if it is
  # accessible from the OS.
  iface[:management] = false

  #  iface[:vendor] = nil #FIXME: NOT IMPLEMENTED
  #  iface[:version] = nil #FIXME: NOT IMPLEMENTED

  # Get MAC address
  # ruby 1.9
  iface[:mac] = iface[:addresses].select{|key,value| value == {'family'=>'lladdr'}}.key({'family'=>'lladdr'})
  # ruby 1.8
  #iface[:mac] = iface[:addresses].select{|key,value| value == {'family'=>'lladdr'}}[0][0]

  #save the state of interface to restore it afterwards
  popen4("cat /sys/class/net/#{dev}/operstate") do |pid, stdin, stdout, stderr|
    case stdout.chomp()
    when "unknown", "lowerlayerdown", "testing", "dormant", "up"
      ifaceState = "up"
    when "notpresent", "down"
      ifaceState = "down"
    else
      ifaceState = "up"
    end
  end
  #Set all interfaces up before calling ethtool. (carrier and rate state are not available if interface is down)
  system("ip link set dev #{dev} up")
  #Wait a moment before probing the interface
  sleep 2
  popen4("ethtool #{dev}; ethtool -i #{dev}") do |pid, stdin, stdout, stderr|
    stdin.close
    stdout.each do |line|
#      if line =~ /^[[:blank:]]*Link detected: /
#        iface[:enabled] = ( line.chomp.split(": ").last.eql?('yes') )
#      end
      if line =~ /^[[:blank:]]*Speed: /
        if line =~ /Unknown/
          iface[:rate] = ""
          # enabled => true if there is any cable connected to this interface (eg speed is know by ethtool)
          iface[:enabled] = false
        else
          iface[:rate] = line.chomp.split(": ").last.gsub(/([GMK])b\/s/){'000000'}
          iface[:enabled] = true
        end
      end
      if line =~ /^\s*driver: /
        iface[:driver] = line.chomp.split(": ").last
      end
    end
  end
  begin
    res = Resolv.getaddress(hostname + '-' + dev)
  rescue Exception => e
    # No such entry in DNS => ignoring...
  end
  ip = iface[:addresses].select{|key,value| value[:family] == 'inet'}.to_a
  iface[:ip] = ip[0][0] if ip.size > 0
  ip6 = iface[:addresses].select{|key,value| value[:family] == 'inet6'}.to_a
  iface[:ip6] = ip6[0][0] if ip6.size > 0
  if iface[:ip].nil? and (File.exist?('/sbin/brctl') or File.exist?('/usr/sbin/brctl'))
    #bridge?
    popen4("brctl show") do |pid, stdin, stdout, stderr|
      stdin.close
      stdout.each do |line|
        if line =~ /(\S*)\s*(\S*)\s*(\S*)\s*(\S*)\s*/
          de = Regexp.last_match(4)
          br = Regexp.last_match(1)
          if de == dev
            ip = interfaces[br][:addresses].select{|key,value| value[:family] == 'inet'}.to_a
            ip6 = interfaces[br][:addresses].select{|key,value| value == {'family'=>'inet'}}.to_a
            iface[:ip] = ip[0][0] if ip.size > 0
            iface[:ip6] = ip6[0][0] if ip6.size > 0
          end
        end
      end
    end
  end
  iface[:mounted] = ( not iface[:ip].nil? )
  #Restore previous interface state
  system("ip link set dev #{dev} #{ifaceState}")
end

# Process ib interfaces
interfaces.select { |d,i| %w{ ib }.include?(i[:type]) }.each do |dev,iface|

  # It is likely that an interface is not the management interface if it is
  # accessible from the OS.
  iface[:management] = false

  iface[:vendor] = nil #FIXME: NOT IMPLEMENTED
  iface[:version] = nil #FIXME: NOT IMPLEMENTED

  # Get MAC address
  if File.exist?('/sys/class/infiniband/mthca0/ports')
    guid_prefix = "20:00:55:04:01:"
  elsif File.exist?('/sys/class/infiniband/mlx4_0/ports')
    guid_prefix = "20:00:55:00:41:"
    #FIXME: else ???
  end
  iface[:mac] = guid_prefix + File.read(File.join('/sys/class/net', dev, 'address')).chomp.split(':')[5..20].join(':')

  iface[:enabled] = false #FIXME: NOT IMPLEMENTED
  #iface[:driver]  = nil #FIXME: NOT IMPLEMENTED

  ca = ""
  popen4("ibstat") do |pid, stdin, stdout, stderr|
    stdin.close
    stdout.each do |line|
      if line =~ /^[[:blank:]]*CA '/
        ca = line.gsub("CA","")
        ca = ca.gsub(" ","")
        ca = ca.gsub("'","")
      end
      if line =~ /^[[:blank:]]*CA type/
        iface[:version] = line.chomp.split(": ").last
      end
    end
  end

  if !ca.empty?
    num = "#{(iface[:number].to_i)+1}"
    popen4("ibstat #{ca.chomp!} #{num}") do |pid, stdin, stdout, stderr|
      stdin.close
      stdout.each do |line|
        if line =~ /^Rate/
          iface[:rate] = line.chomp.split(": ").last.to_i*1000000000
        end
        if line =~ /^State/
          iface[:enabled] = line.chomp.split(": ").last.eql?('Active') #or line.chomp.split(": ").last.eql?('Initializing')) See #7250 and #7244
        end
      end
    end
  end
  
  # The interface is enabled iff state is 'Active' and /sys/class/infiniband/mlx4_0 exists.
  iface[:enabled] = iface[:enabled] && File.exist?('/sys/class/infiniband/mlx4_0')

  begin
    res = Resolv.getaddress(hostname + '-' + dev)
  rescue Exception => e
    # No such entry in DNS => ignoring...
  end

  ip = iface[:addresses].select{|key,value| value[:family] == 'inet'}.to_a
  iface[:ip] = ip[0][0] if ip.size > 0
  ip6 = iface[:addresses].select{|key,value| value[:family] == 'inet6'}.to_a
  iface[:ip6] = ip6[0][0] if ip6.size > 0
  iface[:mounted] = ( not iface[:ip].nil? )
  iface[:driver] = "mlx4_core"
end

# Process management interface

# Get MAC address from ipmitool if possible
if File.exist?('/usr/bin/ipmitool')
  popen4("/usr/bin/ipmitool lan print") do |pid, stdin, stdout, stderr|
    stdin.close
    stdout.each do |line|
      if line =~ /^[[:blank:]]*MAC Address/
        interfaces["bmc"] ||= {}
        interfaces["bmc"][:mac] = line.chomp.split(": ").last
      end
      if line =~ /^[[:blank:]]*IP Address/
        interfaces["bmc"] ||= {}
        interfaces["bmc"][:ip] = line.chomp.split(": ").last
      end
    end
  end

  interfaces["bmc"]['management'] = true if interfaces["bmc"]
end
