describe "Gpu" do
  api_gpu_devices = RSpec.configuration.node.api_description['gpu_devices'] || {}
  api_gpu_devices_by_dev = {}
  if api_gpu_devices.length > 0
    api_gpu_devices.each do |card|
      api_gpu_devices_by_dev[card[0]] = card[1]
    end
  end
  ohai_gpu_devices = RSpec.configuration.node.ohai_description[:gpu_devices]

  # List of GPU models for which nvidia-smi is broken on Grid5000
  UNDETECTED_MODELS = [
    "Tesla M2075", # lyon-orion
  ]

  it "should have the correct number of GPU" do
    nb_gpu_ohai = ohai_gpu_devices.length
    nb_gpu_api = api_gpu_devices_by_dev.length
    api_gpu_devices_by_dev.each do |dev,card|
      if UNDETECTED_MODELS.include?(card['model']) then nb_gpu_api -= 1 end
    end
    Utils.test(nb_gpu_ohai, nb_gpu_api, "number of GPUs", true) do |v_ohai, v_api, error_msg|
      expect(v_ohai).to eql(v_api), error_msg
    end
  end

  ohai_gpu_devices.each do |dev,card|
    ['vendor','model','vbios_version','power_default_limit','memory','device','cpu_affinity'].each do |field|
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
