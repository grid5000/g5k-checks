# frozen_string_literal: true

module LsHw
  def self.get_total_ram_memory
    lshw_xml_output = Utils.shell_out('lshw -xml -C memory').stdout
    xml_doc = Nokogiri::XML(lshw_xml_output)
    xml_doc.at_xpath("//node[@id='memory']/size").text.to_i
  end
end
