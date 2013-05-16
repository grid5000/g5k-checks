describe "Memory" do

  before do
    @api = RSpec.configuration.node.api_description['main_memory']
    @system = RSpec.configuration.node.ohai_description
  end

  it "should have the correct size" do
    size_api = 0
    size_api = @api['ram_size'].to_i if @api
    size_ohai = @system[:memory][:total].to_i
    size_ohai = size_ohai*1024
    (size_ohai/100000000).should eq((size_api/100000000)), "#{size_ohai}, #{size_api}, main_memory, ram_size"
  end

end
