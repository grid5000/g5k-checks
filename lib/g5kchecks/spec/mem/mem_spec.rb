describe "Memory" do

  before do
    @api = RSpec.configuration.node.api_description['main_memory']
  end

  it "should have the correct size" do
    size_api = 0
    size_api = @api['ram_size'].to_i if @api
    size_sys = Utils.dmidecode_total_memory
    err = ((size_sys-size_api)/size_api.to_f).abs
    Utils.test(size_sys, size_api, "main_memory.ram_size") do |v_ohai, v_api, error_msg|
      expect(err).to be < 0.15, error_msg
    end
  end
end
