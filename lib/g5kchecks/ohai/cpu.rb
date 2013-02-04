provides "cpu/improve"
require_plugin("cpu")

# We Assume that every cores have the same values
# Intel ou AMD ?
if cpu[:'0'][:model_name] =~ /AMD/
  cpu[:vendor] = "AMD"
  if cpu[:'0'][:model_name] =~ /Opteron/
    cpu[:model] = "AMD Opteron"
    if cpu[:'0'][:model_name] =~ /Processor[^\w]*([^\s]*)/
      cpu[:version] = $1
    end
  end
else
  cpu[:vendor] = "Intel"
  if cpu[:'0'][:model_name] =~ /Xeon/
    cpu[:model] = "Intel Xeon"
    if cpu[:'0'][:model_name] =~ /CPU[^\w]*([^\s]*)/
      cpu[:version] = $1
    end
  end
end

# most of time c'est le seul moyen que j'ai trouvé pour avoir la bonne frequence.
if File.exist?("/sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq")
  file = File.open("/sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq", "r")
  freq = file.read
  file.close
  # frequence en khz
  cpu[:mhz] = (freq.to_i)*1000 if freq
else
  cpu[:mhz] = cpu[:'0'][:mhz].to_i*1000000
end

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
  end
end
