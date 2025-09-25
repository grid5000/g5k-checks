# frozen_string_literal: true

require 'g5kchecks/utils/utils'
require 'nokogiri'

Ohai.plugin(:Cpu) do
  provides 'cpu/improve'
  depends 'cpu'
  depends 'lsb'

  # Execute an external program
  def execute(cmd)
    res = Utils.shell_out(cmd)
    stdout = res.stdout

    raise "#{cmd}: #{res.exitstatus}" if res.error?

    stdout = stdout.split("\n")
    stdout = (stdout.size == 1 ? stdout[0] : stdout)
    stdout
  end

  collect_data do
    lscpu = execute('lscpu')
    arch = Utils.arch

    # We assume that every cores have the same values
    # x86: Intel or AMD
    if arch == 'x86_64'
      if /AMD/.match?(cpu[:'0'][:model_name])
        cpu[:vendor] = 'AMD'
        if cpu[:'0'][:model_name].include?('Opteron')
          cpu[:model] = 'AMD Opteron'
          cpu[:version] = Regexp.last_match(1) if cpu[:'0'][:model_name] =~ /Processor[^\w]*(.*)/
        elsif cpu[:'0'][:model_name].include?('EPYC')
          cpu[:model] = 'AMD EPYC'
          cpu[:version] = Regexp.last_match(1) if cpu[:'0'][:model_name] =~ /AMD EPYC\s+([[:alnum:]]+)\s+(.*)/
        end
      else
        cpu[:vendor] = 'Intel'
        # To support non standard model name like "INTEL(R) XEON(R) PLATINUM 8568Y+", we manually fix the upper case
        cpu[:'0'][:model_name] = cpu[:'0'][:model_name].sub('INTEL', 'Intel').sub('XEON', 'Xeon').sub('PLATINUM', 'Platinum')
        if cpu[:'0'][:model_name] =~ /(Xeon|Atom|Pentium)/
          cpu[:model] = "Intel #{Regexp.last_match(1)}"
          # All Xeon CPUs before Skylake (e.g. "Intel(R) Xeon(R) CPU X vY @ Z" or "Intel(R) Xeon(R) CPU X 0 @ Z" )
          if cpu[:'0'][:model_name] =~ /Intel\(R\) Xeon\(R\) CPU\s+(.+?)(?:\s0)?\s+@/ ||
             cpu[:'0'][:model_name] =~ /Intel\(R\) Xeon\(R\)\s+(.+)\s+CPU\s+@/ ||
             cpu[:'0'][:model_name] =~ /Intel\(R\) Xeon\(R\)\s+(.+)/ ||
             cpu[:'0'][:model_name] =~ /Intel\(R\) Pentium\(R\) CPU (.+)\s+@/
            cpu[:version] = Regexp.last_match(1)
            # Xeon Skylake and after (e.g. "Intel(R) Xeon(R) Gold X CPU @ Z")
            # Intel(R) Xeon(R) Gold XXXX (e.g. "Intel(R) Xeon(R) Gold 6430")
            # Intel(R) Pentium(R) CPU D1517 @ 1.60GHz
          end
        end
      end
    elsif arch == 'aarch64'
      lscpu.each do |line|
        if line =~ /^Vendor ID:\s+ (.+)$/
          cpu[:vendor] = Regexp.last_match(1)
        elsif line =~ /^Model name:\s+ (.+)$/
          cpu[:'0'][:model_name] = Regexp.last_match(1)
          if cpu[:'0'][:model_name] =~ /^ThunderX2 (.+)$/
            cpu[:model] = 'ThunderX2'
            cpu[:version] = Regexp.last_match(1)
          elsif cpu[:'0'][:model_name] =~ /^Cortex-(.+)$/
            cpu[:model] = 'Cortex'
            cpu[:version] = Regexp.last_match(1)
          elsif cpu[:'0'][:model_name] =~ /^Carmel$/
            cpu[:model] = 'Carmel'
            cpu[:version] = 'Unknown'
          elsif line =~ /^Model name:\s+Neoverse-V2/
            cpu[:model] = 'Grace A02  CPU'
            cpu[:version] = 'Unknown'
            cpu[:other_description] = 'Neoverse-V2'
            cpu[:vendor] = 'NVIDIA/ARM'
          else
            cpu[:model] = 'Unknown'
            cpu[:version] = 'Unknown'
          end
        end
      end
    elsif arch == 'ppc64le'
      cpu[:vendor] = Utils.fileread('/proc/device-tree/vendor').strip
      cpu[:'0'][:model_name] = lscpu.grep(/Model name/).first.split(':')[1].strip
      if /^POWER8NVL/.match?(cpu[:'0'][:model_name])
        cpu[:model] = 'POWER8NVL'
        cpu[:version] = lscpu.grep(/Model:/).first.split(':')[1].strip.split(' ')[0]
      else
        cpu[:model] = 'Unknown'
        cpu[:other_description] = 'Unknown'
      end
    end

    if File.exist?('/sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq')
      freq = Utils.fileread('/sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq')
      # frequence en khz
      cpu[:mhz] = freq.to_i * 1000 if freq
    else
      cpu[:mhz] = cpu[:'0'][:mhz].to_i * 1_000_000
    end

    cpu[:mhz] = (cpu[:mhz].to_f / 1_000_000_000)
    cpu[:mhz] = if cpu[:vendor] == 'Intel'
                  format('%.2f', cpu[:mhz]).to_f
                else
                  format('%.1f', cpu[:mhz]).to_f
                end
    cpu[:mhz] = (cpu[:mhz] * 1_000_000_000).to_i

    # TODO: remove condition when switching to Debian Bullseye
    if lsb[:codename] == 'bullseye'
      lscpu_caches = execute('lscpu --caches -B')
      lscpu_caches.each do |line|
        cpu[:L1d] = line.chomp.split[1].lstrip.to_i if /^L1d/.match?(line)
        cpu[:L1i] = line.chomp.split[1].lstrip.to_i if /^L1i/.match?(line)
        cpu[:L2] = line.chomp.split[1].lstrip.to_i if /^L2/.match?(line)
        cpu[:L3] = line.chomp.split[1].lstrip.to_i if /^L3/.match?(line)
      end
      [:L1d, :L1i, :L2, :L3].each do |c|
        cpu[c] = 0 unless cpu.has_key?(c)
      end
    else
      lscpu.each do |line|
        cpu[:L1d] = line.chomp.split(': ').last.lstrip.sub('K', '') if /^L1d/.match?(line)
        cpu[:L1i] = line.chomp.split(': ').last.lstrip.sub('K', '') if /^L1i/.match?(line)
        cpu[:L2] = line.chomp.split(': ').last.lstrip.sub('K', '') if /^L2/.match?(line)
        cpu[:L3] = line.chomp.split(': ').last.lstrip.sub('K', '') if /^L3/.match?(line)
      end
      [:L1d, :L1i, :L2, :L3].each do |c|
        cpu[c] = cpu[c].to_i * 1024
      end
    end

    # Parsing 'lscpu -p' output to retrieve :nb_procs, :nb_cores and :nb_threads
    # 'lscpu -p' output format :
    ## CPU,Core,Socket,Node,,L1d,L1i,L2,L3
    # 0,0,0,0,,0,0,0,0
    # 1,0,0,0,,0,0,0,0
    # 2,1,0,0,,1,1,1,0
    # 3,1,0,0,,1,1,1,0

    lscpu_p = execute('lscpu -p').grep(/^[^#]/) # skip header lines
    lscpu_p.map! { |line| line.split(',') } # split each line
    lscpu_p = lscpu_p.transpose # transpose the data
    lscpu_p_count = lscpu_p.map { |line| line.uniq.count } # count

    if cpu[:model] == 'Carmel'
      cpu[:nb_procs] = 1
    else
      cpu[:nb_procs] = lscpu_p_count[2]
    end
    cpu[:nb_cores] = lscpu_p_count[1]
    cpu[:nb_threads] = lscpu_p_count[0]

    # :ht_capable
    if arch == 'ppc64le'
      # We assume that we always have SMT on ppc64 (maybe it will not always be
      # true)
      cpu[:ht_capable] = true
      cpu[:ht_enabled] = !execute('ppc64_cpu --smt').include?('SMT is off')

      # There is no feature flags on ppc64
      cpu[:'0'][:flags] = 'none'
    else
      cpu_flags = begin
                    lscpu.grep(/Flags:\t*/)[0]
                  rescue StandardError
                    'unknown'
                  end
      cpu[:ht_capable] = cpu_flags.include?(" ht ")
      cpu[:ht_enabled] = cpu[:nb_threads] != cpu[:nb_cores]
      cpu[:sev_np_enabled] = cpu_flags.include?(" sev ")

      # cpu flags
      cpu[:'0'][:flags] = cpu_flags.split[1..-1]
    end

    # HACK: - see #7309
    # There is a bug in /proc/cpuinfo concerning the ht flag for grimani (E5-2603 v3)
    # https://en.wikipedia.org/wiki/List_of_Intel_Xeon_microprocessors#.22Haswell-EP.22_.2822_nm.29_Efficient_Performance
    #  All [intel] models support [...] Hyper-threading (except E5-1603
    #  v3, E5-1607 v3, E5-2603 v3, E5-2609 v3, E5-2628 v3, E5-2663 v3, E5-2685 v3 and
    #  E5-4627 v3)
    cpu[:ht_capable] = false if /E5-2603 v3/.match?(cpu[:'0'][:model_name])


    # pstate
    cpu[:pstate_driver] = begin
                            Utils.fileread('/sys/devices/system/cpu/cpu0/cpufreq/scaling_driver')
                          rescue StandardError
                            'none'
                          end
    cpu[:pstate_governor] = begin
                              Utils.fileread('/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor')
                            rescue StandardError
                              'none'
                            end

    if cpu[:pstate_driver] != 'none'
      cpu[:pstate_max_cpu_speed] = begin
                                     Utils.fileread('/sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq').to_i
                                   rescue StandardError
                                     nil
                                   end
      cpu[:pstate_min_cpu_speed] = begin
                                     Utils.fileread('/sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq').to_i
                                   rescue StandardError
                                     nil
                                   end
    end

    # :turboboost_enabled
    if cpu[:pstate_driver] == 'intel_pstate' || cpu[:pstate_driver] == 'intel_cpufreq'
      cpu[:turboboost_enabled] = begin
                                   (Utils.fileread('/sys/devices/system/cpu/intel_pstate/no_turbo') == '0')
                                 rescue StandardError
                                   false
                                 end
    elsif cpu[:pstate_driver] == 'acpi-cpufreq'
      cpu[:turboboost_enabled] = begin
                                   (Utils.fileread('/sys/devices/system/cpu/cpufreq/boost') == '1')
                                 rescue StandardError
                                   false
                                 end
    else
      cpu[:turboboost_enabled] = false
    end

    # cstate
    cpu[:cstate_driver] = begin
                            Utils.fileread('/sys/devices/system/cpu/cpuidle/current_driver')
                          rescue StandardError
                            'none'
                          end
    cpu[:cstate_governor] = begin
                              Utils.fileread('/sys/devices/system/cpu/cpuidle/current_governor_ro')
                            rescue StandardError
                              'none'
                            end

    # cpu core numbering (see bug 11023)
    # See also https://www.grid5000.fr/w/TechTeam:CPU_core_numbering
    doc = Nokogiri::XML(`lstopo --of xml`)
    packages = doc.xpath("//object[@type='Package']")
    pu_ids = packages.first.xpath("object//object[@type='PU']").map { |pu| pu.attribute('os_index').value.to_i }.sort

    cpucount = packages.length
    # Default cpu_core_numbering is contiguous (for mono CPU machines it is by choice)
    cpu[:cpu_core_numbering] = 'contiguous'
    if cpucount > 1
      if pu_ids.reject { |e| e % cpucount == 0 }.empty?
        # If all PU ids for the first CPU are multiple of the cpucount, then it ought to be round-robin
        cpu[:cpu_core_numbering] = 'round-robin'
      elsif pu_ids.max < pu_ids.length
        # If all PU ids for the first CPU are inferior than the PU ids count of 1 CPU, then all threads
        # are numbered before moving to the next CPU.
        cores = doc.xpath("//object[@type='Core']")
        pu_ids_first_core = cores.first.xpath("object[@type='PU']").map { |pu| pu.attribute('os_index').value.to_i }.sort
        if pu_ids_first_core.select{|pu| [0, 1].include?(pu) } == [0, 1]
          # On POWER CPUs, all threads of a given core are numbered in a contiguous way.
          cpu[:cpu_core_numbering] = 'contiguous-grouped-by-threads'
        else
          # On ARM CPUs, all cores tend to be numbered first, then threads are numbered.  The PU ids of the
          # threads of the first core will be discontinuous.
          cpu[:cpu_core_numbering] = 'contiguous-including-threads'
        end
      end
    end
  end
end
