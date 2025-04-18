# frozen_string_literal: true

describe 'BMC' do
  before(:all) do
    unless RSpec.configuration.node.api_description.empty?
      @api = RSpec.configuration.node.api_description['network_adapters'].find do |na|
        na['management'] == true
      end
    end
    @ohai = RSpec.configuration.node.ohai_description[:network][:interfaces][:bmc]
  end

# bmc_vendor_tool is set to 'none' when g5k-check cannot get BMC information from the system.
# However, BMC information may be set manually in the reference-api.
# Thus, we skip the tests in that case, because differences between what g5k-check reports (nothing) and the content or the reference-repository (possibly something) are indeed ok.
  if RSpec.configuration.node.api_description == {} || RSpec.configuration.node.api_description['management_tools']['bmc_vendor_tool'] != "none"

    it 'should have the correct IPv4' do
      ip_api = ''
      ip_ohai = ''
      ip_api = @api['ip'] if @api
      ip_ohai = @ohai['ip'] if @ohai
      Utils.test(ip_ohai, ip_api, 'network_adapters/bmc/ip') do |v_ohai, v_api, error_msg|
        expect(v_ohai).to eql(v_api), error_msg
      end
    end

    it 'should have the correct Mac Address' do
      mac_api = ''
      mac_ohai = ''
      mac_api = @api['mac'] if @api
      mac_ohai = @ohai['mac'] if @ohai
      Utils.test(mac_ohai, mac_api, 'network_adapters/bmc/mac') do |v_ohai, v_api, error_msg|
        expect(v_ohai).to eql(v_api), error_msg
      end
    end

    it 'should be a management card' do
      mgt_api = nil
      mgt_ohai = nil
      mgt_api = @api['management'] if @api
      mgt_ohai = @ohai['management'] if @ohai
      Utils.test(mgt_ohai, mgt_api, 'network_adapters/bmc/management') do |v_ohai, v_api, error_msg|
        expect(v_ohai).to eql(v_api), error_msg
      end
    end

    it 'should have the correct version' do
      mgt_api = RSpec.configuration.node.api_description['bmc_version']
      mgt_ohai = RSpec.configuration.node.ohai_description[:bmc]['version']
      Utils.test(mgt_ohai, mgt_api, 'bmc_version') do |v_ohai, v_api, error_msg|
        expect(v_ohai).to eql(v_api), error_msg
      end
    end
  end
end
