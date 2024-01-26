# frozen_string_literal: true

# List of GPU models for which nvidia-smi is broken on Grid5000
UNDETECTED_MODELS = [
  'Tesla K40m',  # nancy-grimani
  'Tesla K80',   # rennes-abacus1
  'Tesla M2075', # lyon-orion
  'AGX Xavier'   # toulouse-estats
].freeze

describe 'Gpu' do
  api_gpu_devices = RSpec.configuration.node.api_description['gpu_devices'] || {}
  api_gpu_devices_by_dev = {}
  unless api_gpu_devices.empty?
    api_gpu_devices.each do |card|
      api_gpu_devices_by_dev[card[0]] = card[1]
    end
  end
  ohai_gpu_devices = RSpec.configuration.node.ohai_description[:gpu_devices]

  it 'should have the correct number of GPU' do
    nb_gpu_ohai = ohai_gpu_devices.length
    nb_gpu_api = api_gpu_devices_by_dev.length
    api_gpu_devices_by_dev.each do |_dev, card|
      nb_gpu_api -= 1 if UNDETECTED_MODELS.include?(card['model'])
    end
    Utils.test(nb_gpu_ohai, nb_gpu_api, 'number of GPUs', true) do |v_ohai, v_api, error_msg|
      expect(v_ohai).to eql(v_api), error_msg
    end
  end

  ohai_gpu_devices.each do |dev, card|
    %w[vendor model vbios_version power_default_limit memory device cpu_affinity].each do |field|
      it "should have information about #{field} for #{dev}" do
        # We compare two strings because cpu_affinity is typed as a string when coming from the API (whereas memory is a Fixnum)
        # On the OHAI side, fields are typed as expected (i.e cpu_affinity is typed as a Fixnum)
        gpu_ohai = card[field.to_sym].to_s
        gpu_api = api_gpu_devices_by_dev[dev].nil? ? nil : api_gpu_devices_by_dev[dev][field].to_s
        Utils.test(gpu_ohai, gpu_api, "gpu_devices/#{dev}/#{field}") do |v_ohai, v_api, error_msg|
          expect(v_ohai).to eql(v_api), error_msg
        end
      end
    end
  end
end
