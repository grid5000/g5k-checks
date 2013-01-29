describe "BMC" do

  before(:all) do
    @api = RSpec.configuration.node.api_description["network_adapters"]
    @sytem = RSpec.configuration.node.ohai_description[:network][:interfaces]
  end

  it "managment card should have the correct MAC" do
    name_api = ""
    name_api = @api[i]['interface'] if @api
    name_lshw = @sytem['mac']
    name_lshw.should eql(name_api), "#{name_lshw}, #{name_api}, network_adapters, mac"
  end

end
