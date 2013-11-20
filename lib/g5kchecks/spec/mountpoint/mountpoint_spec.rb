describe "MountPoint" do

  RSpec.configuration.node.get_wanted_mountpoint.each { |m|

    it "should have the correct mount point" do
      line = Utils.mount_grep(m)
      line.size.should_not eql(0), "mount point #{m} not exist, #{m}" 
    end

  }

end
