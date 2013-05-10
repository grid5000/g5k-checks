provides "filesystem/improve"
require_plugin("filesystem")

# complete les infos des sytèmes de fichier avec le fstab
file_fstab = File.open("/etc/fstab")
fstab = file_fstab.read
file_fstab.close
fstab.each_line do |line|
  next if line =~ /^#/
  if line =~ /([^\s]*)\s*([^\s]*)\s*([^\s]*)\s*([^\s]*)\s*([^\s]*)\s*([^\s]*)\s*/
    filesys = Regexp.last_match(1)
    filesystem[filesys] = Mash.new unless filesystem.has_key?(filesys)
    filesystem[filesys]["fs_type"] = Regexp.last_match(3)
    filesystem[filesys]["dump"] = Regexp.last_match(5)
    filesystem[filesys]["pass"] = Regexp.last_match(6)
    filesystem[filesys]["options"] = Regexp.last_match(4).split(",")
    filesystem[filesys]["mount_point"] = Regexp.last_match(2)
    filesystem[filesys]["file_system"] = filesys
  end
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
        next if line =~ /^$/
        if line =~ /^\s([\d]*)[\s]*([^\s]*)\s*([^\s]*)\s*([^\s]*)\s*([^\s]*)\s*([^\s]*)\s*([^\s]*)$/
          num = Regexp.last_match(1)
          layout[num] = Hash.new
          layout[num][:start] = Regexp.last_match(2)
          layout[num][:end] = Regexp.last_match(3)
          layout[num][:size] = Regexp.last_match(4)
          layout[num][:type] = Regexp.last_match(5)
          six = Regexp.last_match(6)
          sev = Regexp.last_match(7)
          if Regexp.last_match(5) =~ /extended/
            layout[num][:fs] = ""
            layout[num][:flags] = six
          else
            layout[num][:fs] = six
            layout[num][:flags] = sev
          end
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
    end
    filesystem["layout"]= layout
  end
end
