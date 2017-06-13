# coding: utf-8

require 'g5kchecks/utils/dmidecode'

class String
  def force_encoding(enc)
    self
  end
end

module Utils

  KIBI = 1024;
  KILO = 1000;
  MEBI = 1024*1024;
  MEGA = 1000*1000;
  GIBI = MEBI*1024;
  GIGA = MEGA*1000;

  def Utils.convert_storage(value)
    value*GIBI/GIGA/GIGA
  end

  def Utils.inv_convert_storage(value)
    (value*GIGA*GIGA)/GIBI
  end

  def self.autovivifying_hash
    Hash.new {|ht,k| ht[k] = autovivifying_hash}
  end

  def Utils.interface_type(type)
    #Ref API: interface
    case type
    when /^en/,"eth" then return 'Ethernet'
    when "br"        then return 'Bridge'
    when "ib"        then return 'InfiniBand'
    when "myri"      then return 'Myrinet'
    end
  end

  #Get the given interface up/down status
  def Utils.interface_operstate(dev)
    ifaceState = "down"
    case Utils.shell_out("cat /sys/class/net/#{dev}/operstate").stdout.chomp()
    when "unknown", "testing", "dormant", "up"
      ifaceState = "up"
    when "notpresent", "lowerlayerdown", "down"
      ifaceState = "down"
    end
    ifaceState
  end

  #Get ethtool information on iface rate
  def Utils.interface_ethtool(dev)
    infos = {}
    stdout = Utils.shell_out("/sbin/ethtool #{dev}; /sbin/ethtool -i #{dev}").stdout
    stdout.each_line do |line|
      if line =~ /^[[:blank:]]*Speed: /
        if line =~ /Unknown/
          infos[:rate] = nil
          infos[:enabled] = false
        else
          infos[:rate] = line.chomp.split(": ").last.gsub(/([GMK])b\/s/){'000000'}
          infos[:enabled] = true
        end
      end
      if line =~ /^\s*driver: /
        infos[:driver] = line.chomp.split(": ").last
      end
      if line =~ /^\s*version: /
        infos[:version] = line.chomp.split(": ").last
      end
    end
    infos
  end

  # vraiment pas beau mais en ruby 1.9.3 les messages
  # rspec ne peuvent plus être des objets
  def Utils.string_to_object(string)
    return true if string == true || string =~ /true/i
    return false if string == false || string =~ /false/i
    return string.to_i if string =~ /^[0-9]+$/
    return string.to_f if string =~ /^[0-9]+\.[0-9]+$/
    return string.strip
  end

  def Utils.shell_out(command, **options)
    Ohai::Mixin::Command::shell_out(command, options) rescue {}
  end

  def Utils.layout
    layout = {}
    if !File.exist?(File.dirname(__FILE__) + "/../data/layout")
      %x{mkdir -p #{File.join(File.dirname(__FILE__))}/../data/}
      %x{parted /dev/sda print > #{File.join(File.dirname(__FILE__), '/../data/layout')} 2>/dev/null}
    end
    file = File.open(File.dirname(__FILE__) + "/../data/layout")
    cmdline = file.read
    file.close
    cmdline.each_line do |line|
      num, parsed_line = Utils.parse_line_layout(line)
      layout.merge!(parsed_line) if parsed_line != nil
    end
    layout
  end

  def Utils.parse_line_layout(line)
    return if line =~ /^$/
    layout = Hash.new
    if line =~ /^\s([\d]*)[\s]*([^\s]*)\s*([^\s]*)\s*([^\s]*)\s*([^\s]*)\s*([^\s]*)\s*([^\s]*)$/
      num = Regexp.last_match(1)
      layout[num] = Hash.new
      layout[num][:start] = Regexp.last_match(2)
      layout[num][:end] = Regexp.last_match(3)
      layout[num][:size] = Regexp.last_match(4)
      layout[num][:type] = Regexp.last_match(5)
      six = Regexp.last_match(6)
      sev = Regexp.last_match(7)
      if Regexp.last_match(5) =~ /extended/
        layout[num][:fs] = ""
        layout[num][:flags] = six
      else
        layout[num][:fs] = six
        layout[num][:flags] = sev
      end
      return num, layout
    end
    return ""
  end

  def Utils.fstab
    filesystem = Hash.new
    file_fstab = File.open("/etc/fstab")
    fstab = file_fstab.read
    file_fstab.close
    fstab.each_line do |line|
      parsed_line = Utils.parse_line_fstab(line)
      filesystem.merge!(parsed_line) if parsed_line != nil
    end
    filesystem
  end

  def Utils.parse_line_fstab(line)
    return if line =~ /^#/
    filesystem = Hash.new
    if line =~ /([^\s]*)\s*([^\s]*)\s*([^\s]*)\s*([^\s]*)\s*([^\s]*)\s*([^\s]*)\s*/
      filesys = Regexp.last_match(1)
      filesystem[filesys] = Mash.new unless filesystem.has_key?(filesys)
      filesystem[filesys]["fs_type"] = Regexp.last_match(3)
      filesystem[filesys]["dump"] = Regexp.last_match(5)
      filesystem[filesys]["pass"] = Regexp.last_match(6)
      filesystem[filesys]["options"] = Regexp.last_match(4).split(",")
      filesystem[filesys]["mount_point"] = Regexp.last_match(2)
      filesystem[filesys]["file_system"] = filesys
    end
    filesystem
  end

  def Utils.mount_grep(grep)
    mount = Hash.new
    stdout = shell_out("mount | grep '#{grep}'").stdout
    stdout.each_line do |line|
      parsed_line = Utils.parse_line_mount(line)
      mount.merge!(parsed_line) if parsed_line != nil
    end
    mount
  end

  def Utils.mount
    mount = Hash.new
    stdout = shell_out("mount").stdout
    stdout.each_line do |line|
      parsed_line = Utils.parse_line_mount(line)
      mount.merge!(parsed_line) if parsed_line != nil
    end
    mount
  end

  def Utils.parse_line_mount(line)
    return if line =~ /^#/
    filesystem = Hash.new
    if line =~ /([^\s]*)\s*on\s*([^\s]*)\stype*\s*([^\s]*)\s*([^\s]*)\s*/
      mp = Regexp.last_match(1)
      filesystem[mp] = Mash.new unless filesystem.has_key?(mp)
      filesystem[mp]["on"] = Regexp.last_match(2)
      filesystem[mp]["type"] = Regexp.last_match(3)
      filesystem[mp]["options"] = Regexp.last_match(4).gsub(/[()]/,"").split(",")
    end
    filesystem
  end

  #Wrap dmidecode methods into Utils
  def Utils.dmidecode_total_memory
    DmiDecode.get_total_memory
  end

end
