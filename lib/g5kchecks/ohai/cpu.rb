# -*- coding: utf-8 -*-
provides "cpu/improve"
require_plugin("cpu")

require 'open3'

# Read a file. Return an array if the file constains multiple lines. Return nil if the file does not exist.
def fileread(filename)
  output = File.read(filename).split("\n")
  output.size == 1 ? output[0] : output
end

# Execute an external program
def execute(cmd)
  stdout, stderr, status = Open3.capture3(cmd)
  
  raise "#{cmd}: #{status.exitstatus}" unless status.success?

  stdout = stdout.split("\n")
  stdout = (stdout.size == 1 ? stdout[0] : stdout)

  return stdout
end

# We assume that every cores have the same values
# Intel ou AMD ?
if cpu[:'0'][:model_name] =~ /AMD/
  cpu[:vendor] = "AMD"
  if cpu[:'0'][:model_name] =~ /Opteron/
    cpu[:model] = "AMD Opteron"
    if cpu[:'0'][:model_name] =~ /Processor[^\w]*(.*)/
      cpu[:version] = $1
    end
  end
else
  cpu[:vendor] = "Intel"
  if cpu[:'0'][:model_name] =~ /Xeon/
    cpu[:model] = "Intel Xeon"
    if cpu[:'0'][:model_name] =~ /CPU[^\w]*(.*?)(?:\s0)?\s+@/
      cpu[:version] = $1
    end
  end
end

if File.exist?("/sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq")
  file = File.open("/sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq", "r")
  freq = file.read
  file.close
  # frequence en khz
  cpu[:mhz] = (freq.to_i)*1000 if freq
else
  cpu[:mhz] = cpu[:'0'][:mhz].to_i*1000000
end

cpu[:mhz] = (cpu[:mhz].to_f/1000000000)
if  cpu[:vendor] == "Intel"
    cpu[:mhz] = sprintf("%.2f", cpu[:mhz]).to_f
else
    cpu[:mhz] = sprintf("%.1f", cpu[:mhz]).to_f
end
cpu[:mhz] = (cpu[:mhz]*1000000000).to_i

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

#cpu[:extra] = 'test'

# 
cpu[:clock_speed] = (execute('x86info').last.split(" ").last.to_f * 1000 * 1000).to_i rescue 'unknown'

# Parsing 'lscpu -p' output to retrieve :nb_procs, :nb_cores and :nb_threads
# 'lscpu -p' output format :
## CPU,Core,Socket,Node,,L1d,L1i,L2,L3
#0,0,0,0,,0,0,0,0
#1,0,0,0,,0,0,0,0
#2,1,0,0,,1,1,1,0
#3,1,0,0,,1,1,1,0

lscpu_p = execute('lscpu -p').grep(/^[^#]/) # skip header lines
lscpu_p.map!{ |line| line.split(',') }   # split each line
lscpu_p = lscpu_p.transpose              # transpose the data
lscpu_p_count = lscpu_p.map { |line| line.uniq.count } # count

cpu[:nb_procs]   = lscpu_p_count[2]
cpu[:nb_cores]   = lscpu_p_count[1]
cpu[:nb_threads] = lscpu_p_count[0]

# :ht_capable
cpu_flags = fileread('/proc/cpuinfo').grep(/flags\t\t: /)[0] rescue 'unknown'
cpu[:ht_capable] = ! / ht /.match(cpu_flags).nil?

# :ht_enabled
cpu[:ht_enabled] = ! (cpu[:nb_threads] == cpu[:nb_cores])

# pstate
cpu[:pstate_driver]        = fileread('/sys/devices/system/cpu/cpu0/cpufreq/scaling_driver') rescue 'none'
cpu[:pstate_governor]      = fileread('/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor') rescue 'none'

if cpu[:pstate_driver] != 'none'
  cpu[:pstate_max_cpu_speed] = fileread('/sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq').to_i rescue nil
  cpu[:pstate_min_cpu_speed] = fileread('/sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq').to_i rescue nil
end

# :turboboost_enabled
if cpu[:pstate_driver] == 'intel_pstate'
  cpu[:turboboost_enabled] = (fileread('/sys/devices/system/cpu/intel_pstate/no_turbo') == "0") rescue "unknown"
elsif cpu[:pstate_driver] == 'acpi-cpufreq'
  cpu[:turboboost_enabled] = (fileread('/sys/devices/system/cpu/cpufreq/boost') == "1") rescue "unknown"
else
  cpu[:turboboost_enabled] = "unknown"
end

# cstate
cpu[:cstate_driver]   = fileread('/sys/devices/system/cpu/cpuidle/current_driver') rescue 'none'
cpu[:cstate_governor] = fileread('/sys/devices/system/cpu/cpuidle/current_governor_ro') rescue 'none'

if cpu[:cstate_driver] != 'none'
  cstate_names = execute('cat /sys/devices/system/cpu/cpu0/cpuidle/state*/name') rescue nil
  
  # Attempt to force CPU to enter or leave idle state (it updates /sys/devices/system/cpu/cpu*/cpuidle/state*/)

  # convert to array of int
  a = execute("cat /sys/devices/system/cpu/cpu*/cpuidle/state*/usage").map!{|x| x.to_i}
  execute("stress -t 1 -c #{cpu[:nb_threads]}") rescue nil
  sleep 1
  b = execute("cat /sys/devices/system/cpu/cpu*/cpuidle/state*/usage").map!{|x| x.to_i}
  # b-a elements by elements and also group by cpu_id
  diff = [b, a].transpose.map {|v| v.reduce(:-)}.each_slice(cstate_names.size).to_a
  # sum states of all the cpus
  diff = diff.transpose.map{|v| v.reduce(:+)}

  # deeper cstate ?
  cpu[:cstate_max_id] = diff.size - diff.reverse.index { |x| x != 0 } - 1
end

# bios configuration (using sysctl)

syscfg_list = { 
  :ht_enabled => 'LogicalProc',
  :turboboost_enabled => 'ProcTurboMode',
  :cstate_c1e => 'ProcC1E',
  :cstate_enabled => 'ProcCStates',
}

execute('/opt/dell/toolkit/bin/syscfg -o /tmp/syscfg-bios.conf') rescue []
syscfg = File.read('/tmp/syscfg-bios.conf') rescue ''

cpu['configuration'] ||= {}
syscfg_list.each {|k,v|
  cpu['configuration'][k] = (syscfg.match(/^[;]?#{v}=(.*)/)[1] == 'enable' rescue nil)
}

#cpu[:extra2] = 'test2'
