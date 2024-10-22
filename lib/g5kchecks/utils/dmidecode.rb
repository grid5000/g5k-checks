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
      if /^Handle/.match?(line)
        if dmi_section && !dmi_section_data.empty?
          dmi_data[dmi_section] ||= []
          dmi_data[dmi_section] << dmi_section_data
        end
        dmi_section = nil
        dmi_section_data = {}
        dmi_section_array = nil
        look_for_section_name = true
      elsif look_for_section_name
        next if /^\s*DMI type/.match?(line)

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

  def self.get_physical_memory_size(size)
    size_u, unit = size.split(' ')
    size_u.to_i * (1024**(unit == 'GB' ? 3 : 2))
  end

  def self.get_memory
    unless @@memory_devices.empty?
      return @@memory_devices
    end

    dmi_data = get_dmi_data

    return if dmi_data.nil?
    if dmi_data['Memory Device'].nil?
      return if dmi_data['Physical Memory Array'].nil?
      @@memory_devices['Platform'] = {
        size: get_physical_memory_size(dmi_data['Physical Memory Array'][0]['Maximum Capacity']),
        technology: :dram,
        firmware: 'Not Specified'
      }
    else
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
        valid_form_factors = ['DIMM', 'FB-DIMM', 'SODIMM', 'Die', '<OUT OF SPEC>']
        unless size != 'No Module Installed' && valid_form_factors.include?(form_factor)
          next
        end

        @@memory_devices[dev_id] = { size: get_physical_memory_size(size),
                                     technology: memory_type,
                                     firmware: firmware }
      end
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
