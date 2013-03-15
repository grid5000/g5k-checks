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
        if line =~ /([^\s]*)\s*[^s]*start=[^\d]*(\d*),[^s]*size=[^\d]*(\d*),[^I]*Id=[^\d]*(\d*)/
          layout["#{$1}"] = Hash.new
          layout["#{$1}"][:start] = $2
          layout["#{$1}"][:size] = $3
          layout["#{$1}"][:Id] = $4
        end
      end
    end
    layout
  end

  def Utils.fstab
    return {} if !File.exist?(File.dirname(__FILE__) + "/../data/fstab")
    file_fstab = File.open(File.dirname(__FILE__) + "/../data/fstab")
    fstab = file_fstab.read
    file_fstab.close
    filesystem = Hash.new
    fstab.each_line do |line|
      next if line =~ /^#/
      if line =~ /([^\s]*)\s*([^\s]*)\s*([^\s]*)\s*([^\s]*)\s*([^\s]*)\s*([^\s]*)\s*/
        filesys = Regexp.last_match(1)
        filesystem[filesys] = Hash.new
        filesystem[filesys]["file_system"] = Regexp.last_match(1)
        filesystem[filesys]["mount_point"] = Regexp.last_match(2)
        filesystem[filesys]["fs_type"] = Regexp.last_match(3)
        filesystem[filesys]["options"] = Regexp.last_match(4).split(",")
        filesystem[filesys]["dump"] = Regexp.last_match(5)
        filesystem[filesys]["pass"] = Regexp.last_match(6)
      end
    end
    filesystem
  end

end
