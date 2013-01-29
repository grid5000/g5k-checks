require 'ohai'

describe "Architecture" do
  before(:all) do
    @arch_api = RSpec.configuration.node.api_description["architecture"]
    @ohai_system = RSpec.configuration.node.ohai_description
  end

  it "should have the correct number of core" do
    core_api = 0
    if @arch_api
      core_api = @arch_api['smp_size'].to_i
    end
    core_ohai = @ohai_system[:cpu][:real].to_i
    core_ohai.should eql(core_api), "#{core_ohai}, #{core_api}, architecture, smp_size"
  end

   it "should have the correct number of thread" do
    threads_api = 0
    if @arch_api
      threads_api = @arch_api['smt_size'].to_i
    end
    threads_ohai = @ohai_system[:cpu][:total].to_i
    threads_ohai.to_i.should eql(threads_api), "#{threads_ohai}, #{threads_api}, architecture, smt_size"
  end

   it "should have the correct platform type" do
    plat_api = ""
    if @arch_api
      plat_api = @arch_api['platform_type']
    end
    plat_ohai = @ohai_system[:kernel][:machine]
    plat_ohai.should eq(plat_api), "#{plat_ohai}, #{plat_api}, architecture, platform_type"
  end

end
