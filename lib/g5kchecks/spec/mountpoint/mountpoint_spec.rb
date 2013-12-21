describe "MountPoint" do

  RSpec.configuration.node.get_wanted_mountpoint.each { |m|

    it "should have the correct mount point" do
      line = Utils.mount_grep(m)
      line.size.should_not eql(0), "mount point #{m} not exist" 
    end

  }

 Utils.fstab.select { |key,value| value["fs_type"] != "swap" }.each do |k,v|

    it "should be mounted" do
      type_fstab = Utils.mount_grep(v["file_system"])
      type_fstab.size.should_not eql(0), "#{v["file_system"]} is not mounted (according to mount command)"
    end

  end

end
