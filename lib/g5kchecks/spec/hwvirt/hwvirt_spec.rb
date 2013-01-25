describe "Virtual Hardware" do

  before do
    @proc_api = RSpec.configuration.node.api_description['supported_job_types']
    #@proc_lshw = RSpec.configuration.node.search_all_in_hw_description("description","CPU")
    @ohai_system = RSpec.configuration.node.ohai_description
  end

  it "should have the good driver" do
    vhw_type = @ohai_system[:cpu][:'0'][:flags].select{|i|
      i == "svm" || i == "vmx"
    }
    kmod = ""
    @mod_name = ""
    if vhw_type[0] == 'svm'
      kmod = "amd-v"
      @mod_name = "kvm_amd"
    elsif vhw_type[0] == 'vmx'
      kmod = "ivt"
      @mod_name = "kvm_intel"
    end
    kmod_api = ""
    kmod_api = @proc_api['virtual'] if @proc_api
    kmod.should eql(kmod_api), "#{kmod}, supported_job_types, virtual"
#  end
#
#  it "should have virtual driver could be enable" do
    # test if the module could be enable
    if not @mod_name.empty?
      # rmmod.empty? if the loaded module (for testing) must be removed afterwards.
      rmmod = `PATH=/usr/sbin:/sbin:$PATH lsmod | grep -E -e "^kvm_(amd|intel)"`
      system( "PATH=/usr/sbin:/sbin:$PATH modprobe #{@mod_name}").should eql(true)
      system( "PATH=/usr/sbin:/sbin:$PATH modprobe -rf #{@mod_name}" ) if rmmod.empty?
    end
  end

end
