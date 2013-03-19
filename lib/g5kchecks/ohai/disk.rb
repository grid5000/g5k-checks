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
    filesystem[filesys]["file_system"] = Regexp.last_match(1)
  end
end

if File.exist?("/proc/cmdline")
  file = File.open("/proc/cmdline")
  cmdline = file.read
  file.close

  if cmdline =~ /.*root=([^\d]*)(\d).*/
    root_device = $1
    root_part = $2
    popen4("sfdisk -uS -d #{root_device} 2>/dev/null") do |pid, stdin, stdout, stderr|
      stdin.close
      stdout.each do |line|
        if line =~ /([^\s]*)\s*[^s]*start=[^\d]*(\d*),[^s]*size=[^\d]*(\d*),[^I]*Id=[^\d]*(\d*)/
          name_device = Regexp.last_match(1)
          filesystem[name_device] = Mash.new unless filesystem.has_key?(name_device)
          filesystem[name_device][:start] = Regexp.last_match(2)
          filesystem[name_device][:size] = Regexp.last_match(3)
          filesystem[name_device][:Id] = Regexp.last_match(4)
          popen4("tune2fs -l #{name_device}") do |pid, stdin, stdout, stderr|
            stdin.close
            stdout.each do |line|
              if line =~ /^Filesystem state:/
                filesystem[name_device][:state] = line.chomp.split(": ").last.strip
              end
            end
            filesystem[name_device][:state] = "clean" if !filesystem[name_device].has_key?("state")
          end
        end
      end
    end
  end
end

