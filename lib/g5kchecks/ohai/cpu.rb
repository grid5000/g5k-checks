provides "cpu/improve"
require_plugin("cpu")


cpu.each{|cpu|
#
#    # copié de lscpu
#    cache = Hash.new
#    Dir.foreach("/sys/devices/system/cpu/cpu#{cpu[0]}/cache/") do |cache|
#      next if cache == '.' or cache == '..'
#
#      file = File.open("/sys/devices/system/cpu/cpu#{cpu[0]}/cache/#{cache}/type", "r")
#      buf = file.read
#      file.close
#      type = nil
#      case buf
#      when /Data/
#        type = 'd'
#      when /Instruction/
#        type = 'i'
#      end
#
#      file = File.open("/sys/devices/system/cpu/cpu0/cache/#{cache}/size", "r")
#      buf = file.read
#      file.close
#
#      file = File.open("/sys/devices/system/cpu/cpu0/cache/#{cache}/level", "r")
#      level = file.read
#      file.close
#
#      if type
#        cpu[1]["L#{level.chomp}#{type}"] = buf.chomp
#      else
#        cpu[1]["L#{level.chomp}"] = buf.chomp
#      end
#    end
#
    # c'est le seul moyen que j'ai trouvé pour avoir la bonne frequence.
    if File.exist?("/sys/devices/system/cpu/cpu#{cpu[0]}/cpufreq/cpuinfo_max_freq")
    file = File.open("/sys/devices/system/cpu/cpu#{cpu[0]}/cpufreq/cpuinfo_max_freq", "r")
    freq = file.read
    file.close
    # frequence en khz
    cpu[1][:mhz] = (freq.to_i)*1000 if freq
    end

}


popen4("lscpu") do |pid, stdin, stdout, stderr|
        stdin.close
 stdout.each do |line|
    if line =~ /^L1d/
      cpu[:L1d] = line.chomp.split(": ").last.lstrip.sub("K","")
    end
    if line =~ /^L1i/
      cpu[:L1i] = line.chomp.split(": ").last.lstrip.sub("K","")
    end
    if line =~ /^L2/
      cpu[:L2] = line.chomp.split(": ").last.lstrip.sub("K","")
    end
    if line =~ /^L3/
      cpu[:L3] = line.chomp.split(": ").last.lstrip.sub("K","")
    end
    if line =~ /^Socket/
      cpu[:core] = line.chomp.split(": ").last.lstrip.sub("K","")
    end
    if line =~ /^Thread/
      cpu[:thread] = line.chomp.split(": ").last.lstrip.sub("K","")
    end
 end
end


