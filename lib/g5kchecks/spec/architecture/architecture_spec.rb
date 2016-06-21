describe "Architecture" do

  before(:all) do
    @api = RSpec.configuration.node.api_description["architecture"]
    @system = RSpec.configuration.node.ohai_description
  end

  it "should have the correct number of core" do
    core_api = 0
    core_api = @api['smp_size'].to_i if @api
    if @system[:cpu][:real] == 0
      core_ohai = @system[:cpu][:total].to_i
    else
      core_ohai = @system[:cpu][:real].to_i
    end
    core_ohai.should eql(core_api), "#{core_ohai}, #{core_api}, architecture, smp_size"
  end

  it "should have the correct number of thread" do
    threads_api = 0
    threads_api = @api['smt_size'].to_i if @api
    threads_ohai = @system[:cpu][:total].to_i
    threads_ohai.to_i.should eql(threads_api), "#{threads_ohai}, #{threads_api}, architecture, smt_size"
  end

  it "should have the correct platform type" do
    plat_api = ""
    plat_api = @api['platform_type'] if @api
    plat_ohai = @system[:kernel][:machine]
    plat_ohai.should eq(plat_api), "#{plat_ohai}, #{plat_api}, architecture, platform_type"
  end

  keys = [:extra, :extra2, :cpu_speed, 
          :nb_procs, :nb_cores, :nb_threads, 
          :ht_capable, :ht_enabled, 
          :pstate_driver, :pstate_governor, :pstate_max_cpu_speed, :pstate_min_cpu_speed, 
          :turboboost_enabled, 
          :cstate_driver, :cstate_governor, :cstate_max_id, 
          :bios_ht_enabled, :bios_turboboost_enabled, :bios_c1e, :bios_cstates]

  keys.each { |key|

    it "should have the correct value for #{key}" do
      key_api = ""
      key_api = @api[:cpu] if @api
      key_ohai = @system[:cpu][key]
      key_ohai.should eq(key_api), "#{key_ohai}, #{key_api}, architecture, #{key}"
    end
    
  }

end
