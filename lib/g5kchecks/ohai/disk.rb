# frozen_string_literal: true

require 'g5kchecks/utils/utils'

Ohai.plugin(:FileSystem) do
  provides 'filesystem/improve'
  depends 'filesystem'

  collect_data do
    # complete les infos des sytèmes de fichier avec le fstab
    file_fstab = File.open('/etc/fstab')
    fstab = file_fstab.read
    file_fstab.close
    fstab.each_line do |line|
      tmp_fs = Utils.parse_line_fstab(line)
      next if tmp_fs.nil?

      filesystem.merge!(tmp_fs)
    end

    if File.exist?('/proc/cmdline')
      file = File.open('/proc/cmdline')
      cmdline = file.read
      file.close

      if cmdline =~ /.*root=([\S]+).*/
        root_partition = Regexp.last_match(1)
        # the cmdline can be of the form "root=/dev/sda3" or "root=UUID=...", 
        # we need to convert the second form to a path.
        root_partition.gsub!(/^UUID=/,'/dev/disk/by-uuid/')
        # we get the disk from the partition with "lsblk -o pkname" 
        root_device = Utils.shell_out("lsblk -no pkname #{root_partition}").stdout.chomp
        layout = {}
        stdout = Utils.shell_out("parted /dev/#{root_device} print").stdout
        stdout.each_line do |line|
          num, tmp_layout = Utils.parse_line_layout(line)
          next if tmp_layout.nil?

          layout.merge!(tmp_layout)
          if (num == '2') || (num == '3') || (num == '5')
            stdout = Utils.shell_out("tune2fs -l /dev/#{root_device}#{num}").stdout
            stdout.each_line do |line2|
              layout[num][:state] = line.chomp.split(': ').last.strip if line2 =~ /^Filesystem state:/
            end
          end
          layout[num][:state] = 'clean' unless layout[num].key?('state')
        end
        filesystem['layout'] = layout
      end
    end
  end
end
