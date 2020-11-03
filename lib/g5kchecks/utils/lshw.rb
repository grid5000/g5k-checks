# frozen_string_literal: true

module LsHw
  def self.get_total_ram_memory
    lshw_xml_output = Utils.shell_out('lshw -xml -C memory').stdout
    xml_doc = REXML::Document.new(lshw_xml_output)
    REXML::XPath.match(xml_doc, "//node[@id='memory']/size")[0][0].to_s.to_i
  end
end
