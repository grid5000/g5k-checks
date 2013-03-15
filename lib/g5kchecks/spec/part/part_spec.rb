describe "Partitions" do

  before(:all) do
    @sytem = RSpec.configuration.node.ohai_description["filesystem"]
  end

 Utils.layout.each do |k,v|

  it "should have the correct size" do
    size_sys = @sytem["#{k}"][:size]
    size_lay = v[:size]
    size_lay.should eql(size_sys), "filesystem layout size of #{k} is #{size_sys} instead of #{size_lay}"
  end

  it "should have the correct position" do
    pos_sys = @sytem["#{k}"][:start]
    pos_lay= v[:start]
    pos_lay.should eql(pos_sys), "filesystem layout position of #{k} is #{pos_sys} instead of #{pos_lay}"
  end

  it "should have the correct Id" do
    id_sys = @sytem["#{k}"][:Id]
    id_lay = v[:Id]
    id_lay.should eql(id_sys), "filesystem layout Id of #{k} is #{id_sys} instead of #{id_lay}"
  end

  it "should have the correct state" do
    state_sys = @sytem["#{k}"][:state]
    state_sys.should eql("clean"), "filesystem partition state of #{@sytem["#{k}"]} is #{@sytem["#{k}"][:type]}"
  end

 end

 Utils.fstab.each do |k,v|

  it "should have the correct filesystem" do
    fs_sys = @sytem[k]["fs_type"]
    fs_fstab = v["fs_type"]
    fs_sys.should eql(fs_fstab), "filesystem fstab filesystem is #{fs_sys} instead of #{fs_fstab}"
  end

  it "should have the correct mount point" do
    mp_sys = @sytem[k]["mount_point"]
    mp_fstab = v["mount_point"]
    mp_sys.should eql(mp_fstab), "filesystem fstab mount point is #{mp_sys} instead of #{mp_fstab}"
  end

  it "should have the correct type" do
    type_sys = @sytem[k]["file_system"]
    type_fstab = v["file_system"]
    type_sys.should eql(type_fstab), "filesystem fstab type is #{type_sys} instead of #{type_fstab}"
  end

  it "should have the correct number of options" do
      numopt_sys = @sytem[k]["options"].size
      numopt_fstab = v["options"].size
      numopt_sys.should eql(numopt_fstab), "filesystem fstab option are not equals"
  end

  v["options"].each_with_index do |o,i|

    it "should have the correct options" do
      opt = @sytem[k]["options"].include?(o)
      opt.should eql(true), "filesystem fstab option #{o} is not present #{@sytem[k]["mount_options"].to_s}"
    end

  end

  it "should have the correct dump" do
    dump_sys = @sytem[k]["dump"]
    dump_fstab = v["dump"]
    dump_sys.should eql(dump_fstab), "filesystem fstab dump is #{dump_sys} instead of #{dump_fstab}"
  end

  it "should have the correct pass" do
    pass_sys = @sytem[k]["pass"]
    pass_fstab = v["pass"]
    pass_sys.should eql(pass_fstab), "filesystem fstab pass is #{pass_sys} instead of #{pass_fstab}"
  end

 end

end
