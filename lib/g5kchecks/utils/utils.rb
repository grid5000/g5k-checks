# frozen_string_literal: true

require 'g5kchecks/utils/dmidecode'
require 'g5kchecks/utils/lshw'

class String
  def force_encoding(_enc)
    self
  end
end

module Utils
  KIBI = 1024
  KILO = 1000
  MEBI = 1024 * 1024
  MEGA = 1000 * 1000
  GIBI = MEBI * 1024
  GIGA = MEGA * 1000

  def self.convert_storage(value)
    value * GIBI / GIGA / GIGA
  end

  def self.inv_convert_storage(value)
    (value * GIGA * GIGA) / GIBI
  end

  def self.autovivifying_hash
    Hash.new { |ht, k| ht[k] = autovivifying_hash }
  end

  def self.arch
    `uname -m`.chomp
  end

  def self.dmi_supported?
    !['ppc64le'].include?(self.arch)
  end

  def self.interface_type(iface)
    # Ref API: interface
    case iface[:type]
    when /^en/, 'eth' then 'Ethernet'
    when 'br'        then 'Bridge'
    # ib can be Infiniband or OPA, return the good value defined in ohai plugin
    when 'ib'        then iface[:interface]
    when 'myri'      then 'Myrinet'
    end
  end

  # See https://lists.debian.org/debian-user/2017/02/msg00914.html for details
  def self.interface_predictable_name(dev)
    iface_name = nil
    %w[ID_NET_NAME_ONBOARD ID_NET_NAME_SLOT ID_NET_NAME_PATH].each do |udev_property|
      iface_name = Utils.shell_out("/sbin/udevadm test 2>&1 /sys/class/net/#{dev} | grep #{udev_property} | cut -d'=' -f2").stdout.chomp
      break if !iface_name.nil? && iface_name != ''
    end
    iface_name = dev if iface_name.nil? || iface_name == ''
    iface_name
  end

  # Get the given interface up/down status
  def self.interface_operstate(dev)
    ifaceState = 'down'
    case Utils.shell_out("cat /sys/class/net/#{dev}/operstate").stdout.chomp
    when 'unknown', 'testing', 'dormant', 'up'
      ifaceState = 'up'
    when 'notpresent', 'lowerlayerdown', 'down'
      ifaceState = 'down'
    end
    ifaceState
  end

  # Get ethtool information on iface rate
  def self.interface_ethtool(dev)
    infos = {}
    stdout = Utils.shell_out("/sbin/ethtool #{dev}; /sbin/ethtool -i #{dev}").stdout
    stdout.each_line do |line|
      if line =~ /^[[:blank:]]*Speed: /
        if line =~ /Unknown/
          infos[:rate] = nil
          infos[:enabled] = false
        else
          infos[:rate] = line.chomp.split(': ').last.gsub(%r{([GMK])b/s}) { '000000' }
          infos[:enabled] = true
        end
      end
      infos[:driver] = line.chomp.split(': ').last if line =~ /^\s*driver: /
      next unless line =~ /^\s*firmware-version:/

      split_line = line.chomp.split(': ', 2)
      if split_line && split_line.length > 1
        # It is possible that ethtool doesn't return this value
        infos[:firmware_version] = split_line.last
      end
    end
    infos
  end

  # Get vendor/device name from sysfs/lspci
  def self.get_pci_infos(sys_dev_path)
    vendor_id_path = File.join(sys_dev_path, 'vendor').to_s
    device_id_path = File.join(sys_dev_path, 'device').to_s
    vendor_id = Utils.shell_out("cat #{vendor_id_path}").stdout.strip.chomp
    device_id = Utils.shell_out("cat #{device_id_path}").stdout.strip.chomp
    pci_infos = {}
    return pci_infos if device_id.empty? || vendor_id.empty?

    stdout = Utils.shell_out("/usr/bin/lspci -vmm -d #{vendor_id}:#{device_id}").stdout
    stdout.each_line do |line|
      line = line.chomp
      pci_infos[:device] = line.gsub(/^Device:/i, '').strip if line =~ /^Device/
      if line =~ /^Vendor/
        pci_infos[:vendor] = line.gsub(/Vendor:/i, '').sub('Limited', '').sub('Corporation', '').strip
      end
    end
    pci_infos
  end

  # vraiment pas beau mais en ruby 1.9.3 les messages
  # rspec ne peuvent plus être des objets
  def self.string_to_object(string)
    return true if string == true || string =~ /true/i
    return false if string == false || string =~ /false/i
    return string.to_i if string =~ /^[0-9]+$/
    return string.to_f if string =~ /^[0-9]+\.[0-9]+$/

    string.strip
  end

  def self.shell_out(command, **options)
    Ohai::Mixin::Command.shell_out(command, options)
  end

  @@data_layout = nil
  def self.layout
    layout = {}
    @@data_layout = `parted /dev/sda print 2>/dev/null` if @@data_layout.nil?
    @@data_layout.each_line do |line|
      _num, parsed_line = Utils.parse_line_layout(line)
      layout.merge!(parsed_line) unless parsed_line.nil?
    end
    layout
  end

  def self.parse_line_layout(line)
    return if line =~ /^$/

    layout = {}
    if line =~ /^\s([\d]*)[\s]*([^\s]*)\s*([^\s]*)\s*([^\s]*)\s*([^\s]*)\s*([^\s]*)\s*([^\s]*)$/
      num = Regexp.last_match(1)
      layout[num] = {}
      layout[num][:start] = Regexp.last_match(2)
      layout[num][:end] = Regexp.last_match(3)
      layout[num][:size] = Regexp.last_match(4)
      layout[num][:type] = Regexp.last_match(5)
      six = Regexp.last_match(6)
      sev = Regexp.last_match(7)
      if Regexp.last_match(5) =~ /extended/
        layout[num][:fs] = ''
        layout[num][:flags] = six
      else
        layout[num][:fs] = six
        layout[num][:flags] = sev
      end
      return num, layout
    end
    ''
  end

  def self.fstab
    filesystem = {}
    fstab = Utils.fileread('/etc/fstab')
    fstab.each do |line|
      parsed_line = Utils.parse_line_fstab(line)
      filesystem.merge!(parsed_line) unless parsed_line.nil?
    end
    filesystem
  end

  def self.parse_line_fstab(line)
    return if line =~ /^#/

    filesystem = {}
    if line =~ /([^\s]*)\s*([^\s]*)\s*([^\s]*)\s*([^\s]*)\s*([^\s]*)\s*([^\s]*)\s*/
      filesys = Regexp.last_match(1)
      filesystem[filesys] = Mash.new unless filesystem.key?(filesys)
      filesystem[filesys]['fs_type'] = Regexp.last_match(3)
      filesystem[filesys]['dump'] = Regexp.last_match(5)
      filesystem[filesys]['pass'] = Regexp.last_match(6)
      filesystem[filesys]['options'] = Regexp.last_match(4).split(',')
      filesystem[filesys]['mount_point'] = Regexp.last_match(2)
      filesystem[filesys]['file_system'] = filesys
    end
    filesystem
  end

  def self.mount_grep(grep)
    mount = {}
    stdout = shell_out("mount | grep '#{grep}'").stdout
    stdout.each_line do |line|
      parsed_line = Utils.parse_line_mount(line)
      mount.merge!(parsed_line) unless parsed_line.nil?
    end
    mount
  end

  def self.mount
    mount = {}
    stdout = shell_out('mount').stdout
    stdout.each_line do |line|
      parsed_line = Utils.parse_line_mount(line)
      mount.merge!(parsed_line) unless parsed_line.nil?
    end
    mount
  end

  def self.parse_line_mount(line)
    return if line =~ /^#/

    filesystem = {}
    if line =~ /([^\s]*)\s*on\s*([^\s]*)\stype*\s*([^\s]*)\s*([^\s]*)\s*/
      mp = Regexp.last_match(1)
      filesystem[mp] = Mash.new unless filesystem.key?(mp)
      filesystem[mp]['on'] = Regexp.last_match(2)
      filesystem[mp]['type'] = Regexp.last_match(3)
      filesystem[mp]['options'] = Regexp.last_match(4).gsub(/[()]/, '').split(',')
    end
    filesystem
  end

  # Wrap dmidecode methods into Utils
  def self.dmidecode_total_memory(type)
    DmiDecode.get_total_memory(type)
  end

  def self.lshw_total_memory(type)
    case type
    when :dram
      LsHw.get_total_ram_memory
    when :pmem
      # Not yet supported
      nil
    end
  end

  # Memory reported by the OS, dmidecode or lshw are the prefered ways
  def self.meminfo_total_memory(type)
    case type
    when :dram
      Utils.fileread('/proc/meminfo').grep(/MemTotal:/)[0].
        gsub(/^MemTotal:\s*([0-9]*) kB/, '\1').to_i * KIBI
    when :pmem
      # Not yet supported
      nil
    end
  end

  def self.write_api_files
    # Writing node api description files at and of run
    File.open(File.join('/tmp/', RSpec.configuration.node.hostname + '.yaml'), 'w') do |f|
      f.puts RSpec.configuration.api_yaml.to_yaml
    end
    File.open(File.join('/tmp/', RSpec.configuration.node.hostname + '.json'), 'w') do |f|
      f.puts RSpec.configuration.api_yaml.to_json
    end
  end

  def self.add_to_yaml(path, value)
    return if value.nil? || value.to_s.empty?

    hash = RSpec.configuration.api_yaml
    paths = path.split('/')
    until paths.empty?
      p = paths.delete_at(0)
      next if p.empty?

      if !paths.empty?
        hash[p] ||= {}
        hash = hash[p]
      else
        # Because versions returned from ipmitool are x.yz we need to do this
        # to avoid the convertion to a Float by the string_to_object method
        hash[p] = if path == 'bmc_version'
                    value.to_s.encode(Encoding.default_external)
                  else
                    string_to_object(value.to_s.encode(Encoding.default_external))
                  end
      end
    end
  end

  def self.test_disabled?(test_path)
    removetestlist = RSpec.configuration.node.conf['removetestlist']
    return false if removetestlist.nil? || removetestlist.empty?

    removetestlist.each do |testRegexp|
      regexp = Regexp.new(testRegexp)
      return true if regexp =~ test_path
    end
    false
  end

  # Utility method to do rspec test, only if enabled
  # Construct a hash with system values in api mode
  # Set skip_api to false if the value
  def self.test(v_system, v_api, path_api, skip_api = false)
    if test_disabled?(path_api)
      puts "Test #{path_api} is disabled" if RSpec.configuration.node.conf['verbose']
    else
      run_mode = RSpec.configuration.node.conf['mode']
      add_to_yaml(path_api, v_system) if run_mode == 'api' && !skip_api
      yield(v_system, v_api, "#{path_api}: '#{(v_system || 'nil')}' doesn't match api:'#{(v_api || 'nil')}'")
    end
  end

  def self.api_call(url)
    json = nil
    begin
      json = JSON.parse(RestClient::Resource.new(url, user: RSpec.configuration.node.conf['apiuser'], password: RSpec.configuration.node.conf['apipasswd']).get(user_agent: 'g5k-check'))
    rescue RestClient::ServiceUnavailable, RestClient::BadGateway
      retries ||= 0
      if retries < 5
        retries += 1
        sleep 1
        retry
      else
        raise "Fetching #{url} failed too many times..."
      end
    end
    json
  end

  # According to chassis product name, we launch the ipmitool command with a
  # specific timeout and number of retries
  def self.ipmitool_shell_out(args, chassis)
    timeout, retries = case chassis[:product_name]
                       when '8335-GTB'
                         [80, 3]
                       when 'PowerEdge C6220 II'
                         [60, 5]
                       else
                         [nil, 5]
                       end

    try = 0
    shell_out = nil
    begin
      try += 1
      shell_out = if timeout
                    Utils.shell_out("/usr/bin/ipmitool #{args}", timeout: timeout)
                  else
                    Utils.shell_out("/usr/bin/ipmitool #{args}")
                  end
      raise 'ipmitool returned an error' if shell_out.stderr.chomp != ''
    rescue StandardError
      if try < retries
        sleep 1
        retry
      else
        raise "Failed to get data from ipmitool (args: #{args})"
      end
    end

    shell_out
  end

  # Read a file. Return an array if the file constains multiple lines. Return nil if the file does not exist.
  def self.fileread(filename)
    begin
      output = File.readlines(filename, chomp: true)
      output = output.size == 1 ? output[0] : output
    rescue
      output = nil
    end

    output
  end
end
