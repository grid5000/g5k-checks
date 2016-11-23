
module DmiDecode

  # Parse dmidecode data and put it into a hash
  def DmiDecode.get_dmi_data

    output=`/usr/sbin/dmidecode 2>&1`

    if $? != 0
      puts "dmidecode failed: #{output}"
      return nil
    end
    
    look_for_section_name = false
    dmi_section = nil
    dmi_section_data = {}
    dmi_section_array = nil
    dmi_data = {}

    output.split("\n").each do |line|
      if line =~ /^Handle/
        if dmi_section && !dmi_section_data.empty?
          dmi_data[dmi_section] ||= []
          dmi_data[dmi_section] << dmi_section_data
        end
        dmi_section = nil
        dmi_section_data = {}
        dmi_section_array = nil
        look_for_section_name = true
      elsif look_for_section_name
        next if line =~ /^\s*DMI type/
        if line =~ /^\s*(.*)/
          dmi_section = $1
          look_for_section_name = false
        end
      elsif dmi_section && line =~ /^\s*([^:]+):\s*(\S.*)/
        dmi_section_data[$1] = $2;
        dmi_section_array = nil
      elsif dmi_section && line =~ /^\s*([^:]+):$/
        dmi_section_array = $1
      elsif dmi_section && dmi_section_array && line =~ /^\s*(\S.+)$/
        dmi_section_data[dmi_section_array] ||= []
        dmi_section_data[dmi_section_array] << $1
      end
    end
    dmi_data
  end

  #Get dmidecode data and return total physical memory installed (in bytes)
  def DmiDecode.get_total_memory

    physical_memory = 0
    dmi_data = get_dmi_data

    return if dmi_data.nil? or dmi_data['Memory Device'].nil?

    dmi_data['Memory Device'].each do |mem_dev|

      size = mem_dev['Size']
      form_factor = mem_dev['Form Factor']
      locator = mem_dev['Locator']
      # Some systems report little chunks of memory other than
      # main system memory as Memory Devices, the 'DIMM' as
      # form factor seems to indicate main system memory.
      # Unfortunately some DIMMs are reported with a form
      # factor of '<OUT OF SPEC>'.  In that case fall back to
      # checking for signs of it being a DIMM in the locator
      # field.
      if (size != 'No Module Installed' &&
          ((form_factor == 'DIMM' || form_factor == 'FB-DIMM' || form_factor == 'SODIMM') ||
           (form_factor == '<OUT OF SPEC>' && locator =~ /DIMM/)))
        megs, units = size.split(' ')

        next if units != 'MB'
        physical_memory += megs.to_i;
      end
    end
    return physical_memory * (1024 ** 2)
  end

end #Module DmiDecode
