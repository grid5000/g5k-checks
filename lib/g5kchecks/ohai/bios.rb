# frozen_string_literal: true
# fetch bios infos via ipmi for nodes without dmi

require 'g5kchecks/utils/utils'
require 'nokogiri'

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
    xml_doc = Nokogiri::XML(lshw_xml_output)

    bios[:version] = xml_doc.at_xpath("//node[@id='#{xml_node}']/version").text
    bios[:vendor] = xml_doc.at_xpath("//node[@id='#{xml_node}']/description").text

    bios
  end
end
