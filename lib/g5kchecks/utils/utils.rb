# provide some useful functions

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

  def Utils.interface_name(int)
    # Ref API: interface
    case int
    when "eth"  then  return 'Ethernet'
    when "br"   then  return 'Bridge'
    when "ib"   then  return 'InfiniBand'
    when "myri" then  return 'Myrinet'
    end
  end

  # vraiment pas beau mais en ruby 1.9.3 les messages
  # rspec ne peuvent plus être des objets
  def Utils.string_to_object(string)
    return true if string == true || string =~ /true/i
    return false if string == false || string =~ /false/i
    return string.to_i if string =~ /^[0-9]+$/
    return string.to_f if string =~ /^[0-9]+.[0-9]+$/
    return string.strip
  end

  def Utils.layout
    layout = {}
    if File.exist?(File.dirname(__FILE__) + "/../data/layout")
      file = File.open(File.dirname(__FILE__) + "/../data/layout")
      cmdline = file.read
      file.close
      cmdline.each_line do |line|
        next if line =~ /^$/
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
        end
      end
    else # first exectution time (after new deployment)
      %x{mkdir -p #{File.join(File.dirname(__FILE__))}/../data/}
      %x{parted /dev/sda print > #{File.join(File.dirname(__FILE__), '/../data/layout')} 2>/dev/null}
    end
    layout
  end

  def Utils.fstab
    filesystem = Hash.new
    if File.exist?(File.dirname(__FILE__) + "/../data/fstab")
      file_fstab = File.open(File.dirname(__FILE__) + "/../data/fstab")
      fstab = file_fstab.read
      file_fstab.close
      fstab.each_line do |line|
        next if line =~ /^#/
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
      end
    else # first exectution time (after new deployment)
      %x{mkdir -p #{File.join(File.dirname(__FILE__))}/../data/}
      %x{cp /etc/fstab #{File.join(File.dirname(__FILE__), '/../data/')}}
    end
    filesystem
  end

end
