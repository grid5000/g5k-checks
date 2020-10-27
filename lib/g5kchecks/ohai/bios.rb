# frozen_string_literal: true
# fetch bios infos via ipmi for nodes without dmi

Ohai.plugin(:Bios) do
  provides 'bios'
  depends 'devicetree'

  collect_data do
    bios Mash.new
    bios[:bios] = bios_ipmitool
  end

  def bios_ipmitool
    bios Mash.new
    fru = case devicetree[:chassis][:product_name]
          when '8335-GTB'
            47
          else
            return nil
          end

    ipmitool_cmd = "ipmitool fru print #{fru}"
    ipmitool_lines = ''
    ipmitool_status = 1

    begin
      Open3.popen3(ipmitool_cmd) do |_stdin, stdout, _stderr, wait_thr|
        ipmitool_status = wait_thr.value
        ipmitool_lines = stdout.readlines
      end

      if ipmitool_status != 0
        raise "Error running #{ipmitool_cmd}"
      end
    rescue Errno::ENOENT
      nil
    end

    case devicetree[:chassis][:product_name]
    when '8335-GTB'
      ipmitool_lines.each do |line|
        if line =~ /^\s+Product Version\s+\:\s+(.+)$/
          bios[:version] = Regexp.last_match(1)
          break
        end
      end

      bios[:vendor] = 'IBM'
    else
      return nil
    end

    bios
  end
end
