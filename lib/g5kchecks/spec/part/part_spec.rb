
describe "Partitions" do

  before(:all) do
    @system = RSpec.configuration.node.ohai_description["filesystem"]
  end

  Utils.layout.each do |k,v|

    it "should have the correct start" do
      pos_sys = @system["layout"][k][:start] rescue ""
      pos_lay= v[:start]
      Utils.test(pos_sys, pos_lay, "filesystem layout position of #{k}", true) do |v_system, v_api, error_msg|
        expect(v_system).to eql(v_api), error_msg
      end
    end

    it "should have the correct end" do
      end_sys = @system["layout"][k][:end] rescue ""
      end_lay = v[:end]
      Utils.test(end_sys, end_lay, "filesystem layout end of #{k}", true) do |v_system, v_api, error_msg|
        expect(v_system).to eql(v_api), error_msg
      end
    end

    it "should have the correct size" do
      size_sys = @system["layout"][k][:size] rescue ""
      size_lay = v[:size]
      Utils.test(size_sys, size_lay, "filesystem layout size of #{k}", true) do |v_system, v_api, error_msg|
        expect(v_system).to eql(v_api), error_msg
      end
    end

    it "should have the correct type" do
      pos_sys = @system["layout"][k][:type] rescue ""
      pos_lay = v[:type]
      Utils.test(pos_sys, pos_lay, "filesystem layout type of #{k}", true) do |v_system, v_api, error_msg|
        expect(v_system).to eql(v_api), error_msg
      end
    end

    it "should have the correct fs" do
      if k != "3" # don't watch deploy partition (wheezy ext4/ squeeze ext4)
        fs_sys = @system["layout"][k][:fs] rescue ""
        fs_lay = v[:fs]
        Utils.test(fs_sys, fs_lay, "filesystem layout fs of #{k}", true) do |v_system, v_api, error_msg|
          expect(v_system).to eql(v_api), error_msg
        end
      end
    end

    it "should have the correct flags" do
      if k != "3" # don't watch deploy partition (wheezy ext4/ squeeze ext4)
        flags_sys = @system["layout"][k][:flags] rescue ""
        flags_lay = v[:flags]
        Utils.test(flags_sys, flags_lay, "filesystem layout flags of #{k}", true) do |v_system, v_api, error_msg|
          expect(v_system).to eql(v_api), error_msg
        end
      end
    end

    it "should have the correct state" do
      state_sys = @system["layout"][k][:state] rescue ""
      Utils.test(state_sys, "clean", "filesystem layout state of #{k}", true) do |v_system, v_api, error_msg|
        expect(v_system).to eql(v_api), error_msg
      end
    end
  end

  Utils.fstab.each do |k,v|

    it "should have the correct filesystem" do
      fs_sys = @system[k]["fs_type"] rescue ""
      fs_fstab = v["fs_type"]
      Utils.test(fs_sys, fs_fstab, "filesystem fstab filesystem", true) do |v_system, v_api, error_msg|
        expect(v_system).to eql(v_api), error_msg
      end
    end

    it "should have the correct mount point" do
      mp_sys = @system[k]["mount_point"] rescue ""
      mp_fstab = v["mount_point"]
      Utils.test(mp_sys, mp_fstab, "filesystem fstab mount point", true) do |v_system, v_api, error_msg|
        expect(v_system).to eql(v_api), error_msg
      end
    end

    it "should have the correct type" do
      type_sys = @system[k]["file_system"] rescue ""
      type_fstab = v["file_system"]
      Utils.test(type_sys, type_fstab, "filesystem fstab type", true) do |v_system, v_api, error_msg|
        expect(v_system).to eql(v_api), error_msg
      end
    end

    it "should have the correct number of options" do
      numopt_sys = @system[k]["options"].size rescue -1
      numopt_fstab = v["options"].size
      Utils.test(numopt_sys, numopt_fstab, "filesystem fstab options", true) do |v_system, v_api, error_msg|
        expect(v_system).to eql(v_api), error_msg
      end
    end

    v["options"].each_with_index do |o,i|

      it "should have the correct options" do
        opt = @system[k]["options"].include?(o) rescue false
        Utils.test(opt, true, "filesystem fstab option #{o}", true) do |v_system, v_api, error_msg|
          expect(v_system).to eql(v_api), error_msg
        end
      end
    end

    it "should have the correct dump" do
      dump_sys = @system[k]["dump"] rescue ""
      dump_fstab = v["dump"]
      Utils.test(dump_sys, dump_fstab, "filesystem fstab dump", true) do |v_system, v_api, error_msg|
        expect(v_system).to eql(v_api), error_msg
      end
    end

    it "should have the correct pass" do
      pass_sys = @system[k]["pass"] rescue ""
      pass_fstab = v["pass"]
      Utils.test(pass_sys, pass_fstab, "filesystem fstab pass", true) do |v_system, v_api, error_msg|
        expect(v_system).to eql(v_api), error_msg
      end
    end
  end
end
