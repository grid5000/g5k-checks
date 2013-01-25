require 'ohai'
require 'g5kchecks/utils/utils'

describe "Memory" do
  before do
    @mem_api = RSpec.configuration.node.api_description['main_memory']
    @ohai_system = RSpec.configuration.node.ohai_description
  end

  it "should have the correct size" do
    size_api = 0
    if @mem_api
      size_api = @mem_api['ram_size'].to_i
    end
    size_ohai = @ohai_system[:memory][:total].to_i
    size_ohai = size_ohai*1024
    size_ohai.should eq(size_api), "#{size_ohai}, #{size_api}, main_memory, ram_size"
  end

end
