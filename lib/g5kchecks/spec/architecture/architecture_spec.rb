# frozen_string_literal: true

describe 'Architecture' do
  before(:all) do
    @api = RSpec.configuration.node.api_description['architecture']
    @system = RSpec.configuration.node.ohai_description
  end

  it 'should have the correct platform type' do
    plat_api = ''
    plat_api = @api['platform_type'] if @api
    plat_ohai = @system[:kernel][:machine]
    Utils.test(plat_ohai, plat_api, 'architecture/platform_type') do |v_ohai, v_api, error_msg|
      expect(v_ohai).to eql(v_api), error_msg
    end
  end

  %i[nb_procs nb_cores nb_threads cpu_core_numbering].each do |key|
    it "should have the correct value for #{key}" do
      key_ohai = @system[:cpu][key]
      key_api = nil
      key_api = @api[key.to_s] if @api
      Utils.test(key_ohai, key_api, "architecture/#{key}") do |v_ohai, v_api, error_msg|
        expect(v_ohai).to eql(v_api), error_msg
      end
    end
  end
  # end
end
