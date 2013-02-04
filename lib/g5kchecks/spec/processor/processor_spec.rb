describe "Processor" do

  before(:all) do
    @api = RSpec.configuration.node.api_description["processor"]
    @sytem = RSpec.configuration.node.ohai_description
  end

  it "should have the correct frequency" do
    freq_api = ""
    freq_api = @api["clock_speed"] if @api
    freq_lshw = @sytem[:cpu][:mhz]
    freq_lshw.should eql(freq_api), "#{freq_lshw}, #{freq_api}, processor, clock_speed"

  end

  it "should be of the correct instruction set" do
    instr_api = ""
    instr_api = @api["instruction_set"] if @api
    instr_lshw = @sytem[:kernel][:machine].sub('_','-')
    instr_lshw.should eql(instr_api), "#{instr_lshw}, #{instr_api}, processor, instruction_set"
  end

  it "should be of the correct model" do
    desc_api = ""
    desc_api = @api["model"] if @api
    desc_lshw = @sytem[:cpu][:model]
    desc_lshw.should eql(desc_api), "#{desc_lshw}, #{desc_api}, processor, model"
  end

  it "should be of the correct version" do
    version_api = ""
    version_api = @api["version"] if @api
    version_lshw = @sytem[:cpu][:version]
    version_lshw.should eql(version_api), "#{version_lshw}, #{version_api}, processor, version"
  end

  it "should have the correct vendor" do
    vendor_api = ""
    vendor_api = @api["vendor"] if @api
    vendor_lshw = @sytem[:cpu][:vendor]
    vendor_lshw.should eql(vendor_api), "#{vendor_lshw}, #{vendor_api}, processor, vendor"
  end

  it "should have the correct description" do
    desc_api = ""
    desc_api = @api["other_description"] if @api
    desc_lshw = @sytem[:cpu][:'0'][:model_name]
    desc_lshw.should eql(desc_api), "#{desc_lshw}, #{desc_api}, processor, other_description"
  end

  it "should have the correct L1i" do
    l1i_api = ""
    l1i_api = @api["cache_l1i"] if @api
    l1i_lshw = @sytem[:cpu][:L1i].to_i*1024
    l1i_lshw.should eql(l1i_api), "#{l1i_lshw}, #{l1i_api}, processor, cache_l1i"
  end

  it "should have the correct L1d" do
    l1d_api = ""
    l1d_api = @api["cache_l1d"] if @api
    l1d_lshw = @sytem[:cpu][:L1d].to_i*1024
    l1d_lshw.should eql(l1d_api), "#{l1d_lshw}, #{l1d_api}, processor, cache_l1d"
  end

  it "should have the correct L2" do
    l2_api = ""
    l2_api = @api["cache_l2"] if @api
    l2_lshw = @sytem[:cpu][:L2].to_i*1024
    l2_lshw.should eql(l2_api), "#{l2_lshw}, #{l2_api}, processor, cache_l2"
  end

  it "should have the correct L3" do
    l3_api = ""
    l3_api = @api["cache_l3"] if @api
    l3_lshw = @sytem[:cpu][:L3].to_i*1024
    l3_lshw.to_i.should eql(l3_api), "#{l3_lshw}, #{l3_api}, processor, cache_l3"
  end

end
