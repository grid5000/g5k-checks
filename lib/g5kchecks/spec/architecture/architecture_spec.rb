describe "Architecture" do

  before(:all) do
    @api = RSpec.configuration.node.api_description["architecture"]
    @system = RSpec.configuration.node.ohai_description
  end

  it "should have the correct number of core" do
    core_api = 0
    core_api = @api['smp_size'].to_i if @api
    core_ohai = @system[:cpu][:real].to_i
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

end
