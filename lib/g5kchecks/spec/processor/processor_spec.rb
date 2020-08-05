# frozen_string_literal: true

describe 'Processor' do
  before(:all) do
    @api = RSpec.configuration.node.api_description['processor']
    @system = RSpec.configuration.node.ohai_description
  end

  it 'should be of the correct instruction set' do
    instr_api = ''
    instr_api = @api['instruction_set'] if @api
    instr_ohai = @system[:kernel][:machine].sub('_', '-')
    Utils.test(instr_ohai, instr_api, 'processor/instruction_set') do |v_ohai, v_api, error_msg|
      expect(v_ohai).to eql(v_api), error_msg
    end
  end

  it 'should be of the correct model' do
    desc_api = ''
    desc_api = @api['model'] if @api
    desc_ohai = @system[:cpu][:model]
    Utils.test(desc_ohai, desc_api, 'processor/model') do |v_ohai, v_api, error_msg|
      expect(v_ohai).to eql(v_api), error_msg
    end
  end

  it 'should be of the correct version' do
    version_api = ''
    version_api = @api['version'].to_s if @api
    version_ohai = @system[:cpu][:version]
    Utils.test(version_ohai, version_api, 'processor/version') do |v_ohai, v_api, error_msg|
      expect(v_ohai).to eql(v_api), error_msg
    end
  end

  it 'should have the correct vendor' do
    vendor_api = ''
    vendor_api = @api['vendor'] if @api
    vendor_ohai = @system[:cpu][:vendor]
    Utils.test(vendor_ohai, vendor_api, 'processor/vendor') do |v_ohai, v_api, error_msg|
      expect(v_ohai).to eql(v_api), error_msg
    end
  end

  it 'should have the correct description' do
    desc_api = ''
    desc_api = @api['other_description'] if @api
    desc_ohai = @system[:cpu][:'0'][:model_name]
    Utils.test(desc_ohai, desc_api, 'processor/other_description') do |v_ohai, v_api, error_msg|
      expect(v_ohai).to eql(v_api), error_msg
    end
  end

  it 'should have the correct L1i' do
    l1i_api = ''
    l1i_api = @api['cache_l1i'] if @api
    l1i_ohai = @system[:cpu][:L1i].to_i * 1024
    Utils.test(l1i_ohai, l1i_api, 'processor/cache_l1i') do |v_ohai, v_api, error_msg|
      expect(v_ohai).to eql(v_api), error_msg
    end
  end

  it 'should have the correct L1d' do
    l1d_api = ''
    l1d_api = @api['cache_l1d'] if @api
    l1d_ohai = @system[:cpu][:L1d].to_i * 1024
    Utils.test(l1d_ohai, l1d_api, 'processor/cache_l1d') do |v_ohai, v_api, error_msg|
      expect(v_ohai).to eql(v_api), error_msg
    end
  end

  it 'should have the correct L2' do
    l2_api = ''
    l2_api = @api['cache_l2'] if @api
    l2_ohai = @system[:cpu][:L2].to_i * 1024
    Utils.test(l2_ohai, l2_api, 'processor/cache_l2') do |v_ohai, v_api, error_msg|
      expect(v_ohai).to eql(v_api), error_msg
    end
  end

  it 'should have the correct L3' do
    l3_api = ''
    l3_api = @api['cache_l3'] if @api
    l3_ohai = @system[:cpu][:L3].to_i * 1024
    Utils.test(l3_ohai, l3_api, 'processor/cache_l3') do |v_ohai, v_api, error_msg|
      expect(v_ohai).to eql(v_api), error_msg
    end
  end

  [:ht_capable].each do |key|
    it "should have the correct value for #{key}" do
      key_ohai = @system[:cpu][key]

      key_api = nil
      key_api = @api[key.to_s] if @api
      Utils.test(key_ohai, key_api, "processor/#{key}") do |v_ohai, v_api, error_msg|
        expect(v_ohai).to eql(v_api), error_msg
      end
    end
  end

  it 'should have the correct microcode' do
    microcode_api = ''
    microcode_api = @api['microcode'] if @api
    microcode_ohai = @system[:cpu][:microcode]
    Utils.test(microcode_ohai, microcode_api, 'processor/microcode') do |v_ohai, v_api, error_msg|
      expect(v_ohai).to eql(v_api), error_msg
    end
  end
end
