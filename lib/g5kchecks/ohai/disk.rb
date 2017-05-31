# coding: utf-8

require 'g5kchecks/utils/utils'

Ohai.plugin(:FileSystem) do

  provides "filesystem/improve"
  depends "filesystem"

  collect_data do

    # complete les infos des sytèmes de fichier avec le fstab
    file_fstab = File.open("/etc/fstab")
    fstab = file_fstab.read
    file_fstab.close
    fstab.each_line do |line|
      tmp_fs = Utils.parse_line_fstab(line)
      next if tmp_fs == nil
      filesystem.merge!(tmp_fs)
    end

    if File.exist?("/proc/cmdline")
      file = File.open("/proc/cmdline")
      cmdline = file.read
      file.close

      if cmdline =~ /.*root=([^\d]*)(\d).*/
        root_device = $1
        root_part = $2
        layout = {}
        popen4("parted #{root_device} print") do |pid, stdin, stdout, stderr|
          stdin.close
          stdout.each do |line|
	    num, tmp_layout = Utils.parse_line_layout(line)
	    next if tmp_layout == nil
	    layout.merge!(tmp_layout)
            if num == "2" or num == "3" or num == "5"
              popen4("tune2fs -l #{root_device}#{num}") do |pid, stdin, stdout, stderr|
                stdin.close
                stdout.each do |line2|
                  if line2 =~ /^Filesystem state:/
                    layout[num][:state] = line.chomp.split(": ").last.strip
                  end
                end
              end
            end
            layout[num][:state] = "clean" if !layout[num].has_key?("state")
          end
        end
        filesystem["layout"] = layout
      end
    end
  end
end
