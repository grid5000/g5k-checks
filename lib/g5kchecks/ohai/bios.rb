# frozen_string_literal: true
# fetch bios infos via ipmi for nodes without dmi

require 'g5kchecks/utils/utils'
require 'rexml/document'

Ohai.plugin(:Bios) do
  provides 'bios'
  depends 'devicetree'

  collect_data do
    bios Mash.new
    bios[:bios] = bios_lshw
  end

  def bios_lshw
    bios Mash.new
    firmware_id = case devicetree[:chassis][:product_name]
          when '8335-GTB'
            0
          else
            return nil
          end

    xml_node = "firmware:#{firmware_id}"
    lshw_xml_output = Utils.shell_out('lshw -xml -C generic', environment: { 'LC_ALL' => 'C' }).stdout
    xml_doc = REXML::Document.new(lshw_xml_output)

    bios[:version] = REXML::XPath.match(xml_doc, "//node[@id='#{xml_node}']/version")[0][0].to_s
    bios[:vendor] = REXML::XPath.match(xml_doc, "//node[@id='#{xml_node}']/description")[0][0].to_s

    bios
  end
end
