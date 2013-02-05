require 'resolv'

provides "network/network_adapters"
require_plugin("network")
require_plugin("hostname")


interfaces = network[:interfaces]

# Process only eth and myri interfaces first
interfaces.select { |d,i| %w{ eth myri }.include?(i[:type]) }.each do |dev,iface|
  # It is likely that an interface is not the management interface if it is
  # accessible from the OS.
  iface[:management] = false

  #  iface[:vendor] = nil #FIXME: NOT IMPLEMENTED
  #  iface[:version] = nil #FIXME: NOT IMPLEMENTED

  # Get MAC address
  iface[:mac] = iface[:addresses].select{|key,value| value == {'family'=>'lladdr'}}.key({'family'=>'lladdr'})
  popen4("ethtool #{dev}; ethtool -i #{dev}") do |pid, stdin, stdout, stderr|
    stdin.close
    stdout.each do |line|
      if line =~ /^[[:blank:]]*Link detected: /
        iface[:enabled] = ( line.chomp.split(": ").last.eql?('yes') )
      end
      if line =~ /^[[:blank:]]*Speed: /
        if line =~ /Unknown/
          iface[:rate] = ""
      else
        iface[:rate] = line.chomp.split(": ").last.gsub(/([GMK])b\/s/){'000000'}
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
  iface[:mountable] = ( not res.nil? )
  iface[:mounted] = ( not iface[:ip].nil? )

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
  #iface[:rate]    = nil #FIXME: NOT IMPLEMENTED
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
          iface[:enabled] = ( line.chomp.split(": ").last.eql?('Active') )
        end
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
  iface[:mountable] = ( not res.nil? )
  iface[:mounted] = ( not iface[ip].nil? )
  iface[:driver] = "mlx4_core"
end

popen4("ip -o link list | grep -v \" lo[: ]\"") do |pid, stdin, stdout, stderr|
  stdin.close
  stdout.each do |line|

    line =~ /^\d+: (\w+):.*$/
    dev = $1
    interfaces[dev][:up?] = ( line.include?("UP") )
  end
end


# Process management interface

interfaces["mgt"] = Hash.new
# Get MAC address from ipmitool if possible
if File.exist?('/usr/bin/ipmitool')
  interfaces["mgt"][:mac] = %x[ipmitool lan print | grep "MAC Address"].chomp.split(": ").last
else
  interfaces["mgt"][:mac] = nil
end
interfaces["mgt"][:interface] = "Ethernet"
# Get IP + try to find MAC address if not found yet
%w(bmc ipmi mgt rsa).each do |suffix|
  node_mgt = hostname + "-#{suffix}.#{site}.grid5000.fr"
  begin
    ip = Resolv.getaddress( node_mgt )
    interfaces["mgt"][:ip] = ip
    interfaces["mgt"][:network_address] = "\#{node_uid}-#{suffix}.\#{site_uid}.grid5000.fr"
    if interfaces["mgt"][:mac].nil?
      arp = `ping -c 1 #{node_mgt} && /usr/sbin/arp -a #{node_mgt}`
      if arp =~ /([a-fA-F0-9]{2}:){5}([a-fA-F0-9]{2})/
        interfaces["mgt"][:mac] = $~
      end
    end
  rescue Exception => e
    # No such entry in DNS => wrong suffix
  end
end
