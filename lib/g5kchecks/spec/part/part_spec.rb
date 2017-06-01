
describe "Partitions" do

  before(:all) do
    @system = RSpec.configuration.node.ohai_description["filesystem"]
    puts "PARTITIONS TEST, ohai['filesystem = ']\n"
    require 'pp'
    pp @system
  end

  Utils.layout.each do |k,v|

    it "should have the correct start" do
      pos_sys = @system["layout"]["#{k}"][:start]
      pos_lay= v[:start]
      expect(pos_lay).to eql(pos_sys), "filesystem layout position of #{k} is #{pos_sys} instead of #{pos_lay}"
    end

    it "should have the correct end" do
      end_sys = @system["layout"]["#{k}"][:end]
      end_lay = v[:end]
      expect(end_lay).to eql(end_sys), "filesystem layout end of #{k} is #{end_sys} instead of #{end_lay}"
    end

    it "should have the correct size" do
      size_sys = @system["layout"]["#{k}"][:size]
      size_lay = v[:size]
      expect(size_lay).to eql(size_sys), "filesystem layout size of #{k} is #{size_sys} instead of #{size_lay}"
    end

    it "should have the correct type" do
      pos_sys = @system["layout"]["#{k}"][:type]
      pos_lay= v[:type]
      expect(pos_lay).to eql(pos_sys), "filesystem layout position of #{k} is #{pos_sys} instead of #{pos_lay}"
    end

    it "should have the correct fs" do
      if k != "3" # don't watch deploy partition (wheezy ext4/ squeeze ext4)
        fs_sys = @system["layout"]["#{k}"][:fs]
        fs_lay = v[:fs]
        expect(fs_lay).to eql(fs_sys), "filesystem layout fs of #{k} is #{fs_sys} instead of #{fs_lay}"
      end
    end

    it "should have the correct flags" do
      if k != "3" # don't watch deploy partition (wheezy ext4/ squeeze ext4)
        pos_sys = @system["layout"]["#{k}"][:flags]
        pos_lay= v[:flags]
        expect(pos_lay).to eql(pos_sys), "filesystem layout position of #{k} is #{pos_sys} instead of #{pos_lay}"
      end
    end

    it "should have the correct state" do
      state_sys = @system["layout"]["#{k}"][:state]
      expect(state_sys).to eql("clean"), 'filesystem partition state of #{@system[:layout][#{k}"]} is #{@system[:layout]["#{k}"][:state]}'
    end
  end

  Utils.fstab.each do |k,v|

    it "should have the correct filesystem" do
      fs_sys = @system[k]["fs_type"]
      fs_fstab = v["fs_type"]
      expect(fs_sys).to eql(fs_fstab), "filesystem fstab filesystem is #{fs_sys} instead of #{fs_fstab}"
    end

    it "should have the correct mount point" do
      mp_sys = @system[k]["mount_point"]
      mp_fstab = v["mount_point"]
      expect(mp_sys).to eql(mp_fstab), "filesystem fstab mount point is #{mp_sys} instead of #{mp_fstab}"
    end

    it "should have the correct type" do
      type_sys = @system[k]["file_system"]
      type_fstab = v["file_system"]
      expect(type_sys).to eql(type_fstab), "filesystem fstab type is #{type_sys} instead of #{type_fstab}"
    end

    it "should have the correct number of options" do
      numopt_sys = @system[k]["options"].size
      numopt_fstab = v["options"].size
      expect(numopt_sys).to eql(numopt_fstab), "filesystem fstab option are not equals"
    end

    v["options"].each_with_index do |o,i|

      it "should have the correct options" do
        opt = @system[k]["options"].include?(o)
        expect(opt).to eql(true), "filesystem fstab option #{o} is not present #{@system[k]["mount_options"].to_s}"
      end

    end

    it "should have the correct dump" do
      dump_sys = @system[k]["dump"]
      dump_fstab = v["dump"]
      expect(dump_sys).to eql(dump_fstab), "filesystem fstab dump is #{dump_sys} instead of #{dump_fstab}"
    end

    it "should have the correct pass" do
      pass_sys = @system[k]["pass"]
      pass_fstab = v["pass"]
      expect(pass_sys).to eql(pass_fstab), "filesystem fstab pass is #{pass_sys} instead of #{pass_fstab}"
    end

  end

end
