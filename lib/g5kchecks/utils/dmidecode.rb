# frozen_string_literal: true

module DmiDecode
  @@memory_devices = {}
  # Parse dmidecode data and put it into a hash
  def self.get_dmi_data
    output = `/usr/sbin/dmidecode 2>&1`

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
          dmi_section = Regexp.last_match(1)
          look_for_section_name = false
        end
      elsif dmi_section && line =~ /^\s*([^:]+):\s*(\S.*)/
        dmi_section_data[Regexp.last_match(1)] = Regexp.last_match(2)
        dmi_section_array = nil
      elsif dmi_section && line =~ /^\s*([^:]+):$/
        dmi_section_array = Regexp.last_match(1)
      elsif dmi_section && dmi_section_array && line =~ /^\s*(\S.+)$/
        dmi_section_data[dmi_section_array] ||= []
        dmi_section_data[dmi_section_array] << Regexp.last_match(1)
      end
    end
    dmi_data
  end

  def self.get_memory
    dmi_data = get_dmi_data

    return if dmi_data.nil? || dmi_data['Memory Device'].nil?

    if !@@memory_devices.empty?
      return @@memory_devices
    end

    # On the oldest clusters dmidecode does not print the Memory Technology for
    # the DIMMs. When it's the case, we assume that DIMMs are always DRAM
    dmi_data['Memory Device'].each do |mem_dev|
      memory_type = case mem_dev['Memory Technology']
                    when /^DRAM$/, nil
                      :dram
                    when /^Intel.*persistent memory$/
                      :pmem
                    end

      size = mem_dev['Size']
      form_factor = mem_dev['Form Factor']
      firmware = mem_dev['Firmware Version'] == 'Not Specified' ? nil : mem_dev['Firmware Version']

      locator = if mem_dev['Locator'].match(/^DIMM_(.+)$/)
                  $1
                elsif mem_dev['Locator'].match(/^DIMM(\d+)$/) && mem_dev['Bank Locator'].match?(/CPU/)
                  $1.to_i.to_s + '_' + mem_dev['Bank Locator']
                elsif mem_dev['Bank Locator'].match(/^DIMM(\d+)$/) && mem_dev['Locator'].match?(/CPU/)
                  $1.to_i.to_s + '_' + mem_dev['Locator']
                else
                  mem_dev['Locator']
                end

      dev_id = "#{form_factor.downcase}_#{locator.downcase}"

      if @@memory_devices.has_key?(dev_id)
        raise "Overlapping detected, the memory device name #{dev_id} (generated) is already present in the data structure"
      end

      # Consider <OUT OF SPEC> form factor valid if returned size is valid (ex: see lille/chifflet)
      unless size != 'No Module Installed' && (form_factor == 'DIMM' || form_factor == 'FB-DIMM' || form_factor == 'SODIMM' || form_factor == '<OUT OF SPEC>')
        next
      end

      size_u, unit = size.split(' ')

      if unit == 'GB'
        physical_memory = (size_u.to_i * 1024)
      elsif unit == 'MB'
        physical_memory = size_u.to_i
      end

      physical_memory = physical_memory * (1024**2) if physical_memory > 0
      @@memory_devices[dev_id] = { size: physical_memory,
                                   technology: memory_type,
                                   firmware: firmware }
    end

    @@memory_devices
  end

  # Get dmidecode data and return total physical memory installed (in bytes)
  def self.get_total_memory
    memory_total = {}
    memory_devices = get_memory
    memory_devices.each_value do |device|
      memory_total[device[:technology]] ||= 0
      memory_total[device[:technology]] += device[:size]
    end

    memory_total
  end
end # Module DmiDecode
