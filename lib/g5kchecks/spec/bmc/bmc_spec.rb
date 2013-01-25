describe "BMC" do

  before(:all) do
    @net_api = RSpec.configuration.node.api_description["network_adapters"]
    @mgt_lshw = RSpec.configuration.node.ohai_description[:network][:interfaces]#[:mgt]
  end

 it "managment card should have the correct MAC" do
#puts   @mgt_lshw.to_yaml
      name_api = ""
      name_api = @net_api[i]['interface'] if @net_api
      name_lshw = @mgt_lshw['mac']
      name_lshw.should eql(name_api), "#{name_lshw}, #{name_api}, network_adapters, mac"
 end

end
