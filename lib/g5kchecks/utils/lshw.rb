# frozen_string_literal: true

require 'nokogiri'

module LsHw
  def self.get_total_ram_memory
    lshw_xml_output = Utils.shell_out('lshw -xml -C memory').stdout
    xml_doc = Nokogiri::XML(lshw_xml_output)
    xml_doc.at_xpath("//node[@id='memory']/size").text.to_i
  end

  def self.get_memory_devices
    lshw_xml_output = Utils.shell_out('lshw -xml -C memory').stdout
    xml_doc = Nokogiri::XML(lshw_xml_output)
    memory_devices = {}

    xml_doc.xpath("//node[contains(@id,'bank:')]").each do |d|
      dev_id = d.at_xpath("slot").text.gsub(/Physical:.*(DIMM)(\d+)$/, '\1_\2').downcase
      if memory_devices.has_key?(dev_id)
        raise "Overlapping detected, the memory device name #{dev_id} (generated) is already " \
          "present in the data structure"
      end
      memory_devices[dev_id] = {}
      memory_devices[dev_id][:size] = d.at_xpath("size").text.to_i
      if d.at_xpath('description').text.match?(/DDR/)
        memory_devices[dev_id][:technology] = :dram
      else
        raise 'This kind of memory is not yet supported while using lshw'
      end
    end

    memory_devices
  end
end
