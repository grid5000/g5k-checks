
require 'g5kchecks/utils/utils'
require 'rexml/document'

Ohai.plugin(:Cpu) do

  provides "cpu/improve"
  depends "cpu"

  # Read a file. Return an array if the file constains multiple lines. Return nil if the file does not exist.
  def fileread(filename)
    output = File.read(filename).split("\n")
    output.size == 1 ? output[0] : output
  end

  # Execute an external program
  def execute(cmd)
    res = Utils.shell_out(cmd)
    stdout = res.stdout

    raise "#{cmd}: #{res.exitstatus.to_s}" if res.error?

    stdout = stdout.split("\n")
    stdout = (stdout.size == 1 ? stdout[0] : stdout)
    return stdout
  end

  collect_data do
    
    # We assume that every cores have the same values
    # Intel ou AMD ?
    if cpu[:'0'][:model_name] =~ /AMD/
      cpu[:vendor] = "AMD"
      if cpu[:'0'][:model_name] =~ /Opteron/
        cpu[:model] = "AMD Opteron"
        if cpu[:'0'][:model_name] =~ /Processor[^\w]*(.*)/
          cpu[:version] = $1
        end
      elsif cpu[:'0'][:model_name] =~ /EPYC/
        cpu[:model] = "AMD EPYC"
        if cpu[:'0'][:model_name] =~ /AMD EPYC\s+(\d+)\s+(.*)/
          cpu[:version] = $1
        end
      end
    else
      cpu[:vendor] = "Intel"
      if cpu[:'0'][:model_name] =~ /(Xeon|Atom)/
        cpu[:model] = "Intel #{$1}"
        # All Xeon CPUs before Skylake (e.g. "Intel(R) Xeon(R) CPU X vY @ Z" or "Intel(R) Xeon(R) CPU X 0 @ Z" )
        if cpu[:'0'][:model_name] =~ /Intel\(R\) Xeon\(R\) CPU\s+(.+?)(?:\s0)?\s+@/
          cpu[:version] = $1
        # Xeon Skylake and after (e.g. "Intel(R) Xeon(R) Gold X CPU @ Z")
        elsif cpu[:'0'][:model_name] =~ /Intel\(R\) Xeon\(R\)\s+(.+)\s+CPU?\s+@/
          cpu[:version] = $1
        # TODO: Add Atom regex here...
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

    stdout = Utils.shell_out("lscpu").stdout
    stdout.each_line do |line|
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

    # HACK - see #7309
    # There is a bug in /proc/cpuinfo concerning the ht flag for grimani (E5-2603 v3)
    # https://en.wikipedia.org/wiki/List_of_Intel_Xeon_microprocessors#.22Haswell-EP.22_.2822_nm.29_Efficient_Performance
    #  All [intel] models support [...] Hyper-threading (except E5-1603
    #  v3, E5-1607 v3, E5-2603 v3, E5-2609 v3, E5-2628 v3, E5-2663 v3, E5-2685 v3 and
    #  E5-4627 v3)
    cpu[:ht_capable] = false if /E5-2603 v3/.match(cpu[:'0'][:model_name])

    # :ht_enabled
    cpu[:ht_enabled] = ! (cpu[:nb_threads] == cpu[:nb_cores])

    # pstate
    cpu[:pstate_driver] = fileread('/sys/devices/system/cpu/cpu0/cpufreq/scaling_driver') rescue 'none'
    cpu[:pstate_governor] = fileread('/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor') rescue 'none'

    if cpu[:pstate_driver] != 'none'
      cpu[:pstate_max_cpu_speed] = fileread('/sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq').to_i rescue nil
      cpu[:pstate_min_cpu_speed] = fileread('/sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq').to_i rescue nil
    end

    # :turboboost_enabled
    if cpu[:pstate_driver] == 'intel_pstate'
      cpu[:turboboost_enabled] = (fileread('/sys/devices/system/cpu/intel_pstate/no_turbo') == "0") rescue false
    elsif cpu[:pstate_driver] == 'acpi-cpufreq'
      cpu[:turboboost_enabled] = (fileread('/sys/devices/system/cpu/cpufreq/boost') == "1") rescue false
    else
      cpu[:turboboost_enabled] = false
    end

    # cstate
    cpu[:cstate_driver] = fileread('/sys/devices/system/cpu/cpuidle/current_driver') rescue 'none'
    cpu[:cstate_governor] = fileread('/sys/devices/system/cpu/cpuidle/current_governor_ro') rescue 'none'

    # microcode version
    cpu[:microcode] = fileread('/proc/cpuinfo').grep(/microcode\t: /)[0].split(': ')[1] rescue 'unknown'

    # cpu core numbering (see bug 11023)
    doc = REXML::Document.new(`lstopo --of xml`)
    packages = REXML::XPath::match(doc, "//object[@type='Package']")
    pu_ids = packages.first.get_elements("object//object[@type='PU']").map { |pu| pu['os_index'].to_i }.sort
    cpucount = packages.length
    # If all PU ids for the first CPU are multiple of the cpucount, then it's round-robin
    cpu[:cpu_core_numbering] = ((pu_ids.select { |e| e % cpucount != 0 }.empty? and cpucount > 1) ? 'round-robin' : 'contiguous')
  end
end
