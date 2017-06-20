describe 'Disk' do

  def get_api_value(api, ohai, device, key)
    return nil if !(api && api[device] && api[device][key])
    return api[device][key] if !(api[device]['unstable_device_name'] && ohai[device] && ohai[device]['by_id'])
    return unstable_device_value(api, key, ohai[device])
  end

  # If devices names are unstable : reorder devices taken from the ref-api
  def unstable_device_value(api, key, v)
    api = api.values.select { |x| x['by_id'] == v['by_id'] }.first
    return api[key]
  end

  def get_ohai_value(_api, ohai, device, key)
    return nil if !(ohai && ohai[device] && ohai[device][key])
    return Utils.string_to_object(ohai[device][key].to_s)
  end

  api = nil
  tmpapi = RSpec.configuration.node.api_description['storage_devices']
  if tmpapi != nil
    api = {}
    tmpapi.each do |d|
      api[d['device']] = d
    end
  end

  ohai = RSpec.configuration.node.ohai_description["block_device"].select { |key, value| key =~ /[sh]d.*/ && value['model'] != 'vmDisk' }

  # If g5k-checks is called with "-m api" option, then api = nil
  # and we use ohai as a reference. Else we use api as a reference.
  reference = api.nil? ? ohai : api

  reference.each do |k, _v|
    # Need to check the API value here, in order to generate the key 'device'
    # in the yaml and json output files
    it 'should have the correct name' do
      name_api = api[k] if api
      Utils.test(k, name_api, "storage_devices.#{k}.device") do |v_ohai, v_api, error_msg|
        expect(name_api).to_not eql(nil), error_msg
      end
    end

    it 'should have the correct device id' do
      by_id_api = get_api_value(api, ohai, k, 'by_id')
      by_id_ohai = get_ohai_value(api, ohai, k, 'by_id')
      Utils.test(by_id_ohai, by_id_api, "storage_devices.#{k}.by_id")  do |v_ohai, v_api, error_msg|
        expect(v_ohai).to eql(v_api), error_msg
      end
    end

    it 'should have the correct (optional) device path' do
      #Check by_path only if we can get it from the system...
      by_path_api = get_api_value(api, ohai, k, 'by_path')
      by_path_ohai = get_ohai_value(api, ohai, k, 'by_path')
      Utils.test(by_path_ohai, by_path_api, "storage_devices.#{k}.by_path")  do |v_ohai, v_api, error_msg|
        if by_path_ohai.nil? || by_path_ohai.empty?
          expect(true).to be(true), "Device #{k} 'by_path' not available, not testing"
        else
          expect(v_ohai).to eql(v_api), error_msg
        end
      end
    end

    it 'should have the correct size' do
      size_api = get_api_value(api, ohai, k, 'size')
      size_ohai = 0
      size = get_ohai_value(api, ohai, k, 'size')
      size_ohai = size.to_i * 512 if !size.nil?
      Utils.test(size_ohai, size_api, "storage_devices.#{k}.size") do |v_ohai, v_api, error_msg|
        expect(v_ohai).to eql(v_api), error_msg
      end
    end

    it 'should have the correct model' do
      model_api = get_api_value(api, ohai, k, 'model')
      model_ohai = get_ohai_value(api, ohai, k, 'model')
      Utils.test(model_ohai, model_api, "storage_devices.#{k}.model") do |v_ohai, v_api, error_msg|
        expect(v_ohai).to eql(v_api), error_msg
      end
    end

    it 'should have the correct revision' do
      version_api = get_api_value(api, ohai, k, 'rev')
      version_ohai = get_ohai_value(api, ohai, k, 'rev')
      Utils.test(version_ohai, version_api, "storage_devices.#{k}.rev") do |v_ohai, v_api, error_msg|
        expect(v_ohai).to eql(v_api), error_msg
      end
    end

    it 'should have the correct vendor' do
      vendor_api = get_api_value(api, ohai, k, 'vendor')
      vendor_ohai = get_ohai_value(api, ohai, k, 'vendor')
      vendor_from_lshw = get_ohai_value(api, ohai, k, 'vendor_from_lshw')
      vendor_ohai = vendor_from_lshw  if !vendor_from_lshw.nil?
      Utils.test(vendor_ohai, vendor_api, "storage_devices.#{k}.vendor") do |v_ohai, v_api, error_msg|
        expect(v_ohai).to eql(v_api), error_msg
      end
    end
  end
end
