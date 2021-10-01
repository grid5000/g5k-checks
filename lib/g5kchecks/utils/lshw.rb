# frozen_string_literal: true

module LsHw
  def self.get_total_ram_memory
    lshw_xml_output = Utils.shell_out('lshw -xml -C memory').stdout
    xml_doc = REXML::Document.new(lshw_xml_output)
    REXML::XPath.match(xml_doc, "//node[@id='memory']/size")[0][0].to_s.to_i
  end

  def self.get_memory_devices
    lshw_xml_output = Utils.shell_out('lshw -xml -C memory').stdout
    xml_doc = REXML::Document.new(lshw_xml_output)
    memory_devices = {}

    REXML::XPath.match(xml_doc, "//node[contains(@id,'bank:')]").each do |d|
      dev_id = d.elements['slot'][0].to_s.gsub(/Physical:.*(DIMM)(\d+)$/, '\1_\2').downcase
      if memory_devices.has_key?(dev_id)
        raise "Overlapping detected, the memory device name #{dev_id} (generated) is already " \
          "present in the data structure"
      end
      memory_devices[dev_id] = {}
      memory_devices[dev_id][:size] = d.elements['size'][0].to_s.to_i
      if d.elements['description'][0].to_s.match?(/DDR/)
        memory_devices[dev_id][:technology] = :dram
      else
        raise 'This kind of memory is not yet supported while using lshw'
      end
    end

    memory_devices
  end
end
