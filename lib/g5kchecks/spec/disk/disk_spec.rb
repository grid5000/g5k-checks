# frozen_string_literal: true

describe 'Disk' do
  def get_api_value(api, ohai, device, key)
    return nil unless api && api[device] && api[device][key]
    return api[device][key] unless api[device]['unstable_device_name'] && ohai[device] && ohai[device]['by_id']

    unstable_device_value(api, key, ohai[device])
  end

  # If devices names are unstable : reorder devices taken from the ref-api
  def unstable_device_value(api, key, v)
    api = api.values.find { |x| x['by_id'] == v['by_id'].chomp }
    api[key]
  end

  def get_ohai_value(_api, ohai, device, key)
    return nil unless ohai && ohai[device] && ohai[device][key]

    Utils.string_to_object(ohai[device][key].to_s)
  end

  api = nil
  tmp_api = RSpec.configuration.node.api_description['storage_devices']
  unless tmp_api.nil?
    api = {}
    tmp_api.each do |d|
      api[d['by_path'].split('/').last] = d
    end
  end

  # If we are in a user deployed env, only look for main disk +
  # reserved disks.
  # Ignore if api mode, to dump correct information
  g5k_ohai = RSpec.configuration.node.ohai_description['g5k']
  if g5k_ohai && g5k_ohai['user_deployed'] == true && RSpec.configuration.node.conf['mode'] != 'api'
    disks = g5k_ohai['disks']
    api = api.select { |_k, v| disks.include?(v['id']) }
  end

  tmp_ohai = RSpec.configuration.node.ohai_description['block_device'].select { |key, value| (key =~ /[sh]d.*/ || key =~ /nvme.*/) && value['model'] != 'vmDisk' }
  unless tmp_ohai.nil?
    ohai = {}
    tmp_ohai.each do |_k, v|
      ohai[v['by_path'].split('/').last] = v
    end
  end

  # If g5k-checks is called with "-m api" option, then api = nil
  # and we use ohai as a reference. Else we use api as a reference.
  reference = api.nil? ? ohai : api

  # Check that we have the correct number of disks if not deployed by user (the user might see less disks because of reservable disks)
  if g5k_ohai && g5k_ohai['user_deployed'] == false
    it 'should have the correct number of storage devices' do
      # 'true' in fourth parameter means that we do not add the result to the API
      Utils.test(ohai.length, api.length, 'storage_devices/length', true) do |v_ohai, v_api, error_msg|
        expect(v_ohai).to eql(v_api), error_msg
      end
    end
  end

  reference.each do |k, _v|
    it 'should have the correct device id' do
      by_id_api = get_api_value(api, ohai, k, 'by_id')
      by_id_ohai = get_ohai_value(api, ohai, k, 'by_id')
      Utils.test(by_id_ohai, by_id_api, "storage_devices/#{k}/by_id") do |v_ohai, v_api, error_msg|
        expect(v_ohai).to eql(v_api), error_msg
      end
    end

    it 'should have the correct device path' do
      by_path_api = get_api_value(api, ohai, k, 'by_path')
      by_path_ohai = get_ohai_value(api, ohai, k, 'by_path')
      Utils.test(by_path_ohai, by_path_api, "storage_devices/#{k}/by_path") do |v_ohai, v_api, error_msg|
        expect(v_ohai).to eql(v_api), error_msg
      end
    end

    it 'should have the correct size' do
      size_api = get_api_value(api, ohai, k, 'size')
      size_ohai = 0
      size = get_ohai_value(api, ohai, k, 'size')
      size_ohai = size.to_i * 512 unless size.nil?
      Utils.test(size_ohai, size_api, "storage_devices/#{k}/size") do |v_ohai, v_api, error_msg|
        expect(v_ohai).to eql(v_api), error_msg
      end
    end

    it 'should have the correct model' do
      model_api = get_api_value(api, ohai, k, 'model')
      model_ohai = get_ohai_value(api, ohai, k, 'model')
      Utils.test(model_ohai, model_api, "storage_devices/#{k}/model") do |v_ohai, v_api, error_msg|
        expect(v_ohai).to eql(v_api), error_msg
      end
    end

    it 'should have the correct firmware revision' do
      version_api = get_api_value(api, ohai, k, 'firmware_version')
      version_ohai = get_ohai_value(api, ohai, k, 'rev')
      Utils.test(version_ohai, version_api, "storage_devices/#{k}/firmware_version") do |v_ohai, v_api, error_msg|
        if version_ohai.nil?
          expect(true).to be(true), "Device #{k} 'firmware revision' not available, not testing"
        else
          expect(v_ohai).to eql(v_api), error_msg
        end
      end
    end

    it 'should have the storage type' do
      model_api = get_api_value(api, ohai, k, 'storage')
      model_ohai = get_ohai_value(api, ohai, k, 'storage')
      Utils.test(model_ohai, model_api, "storage_devices/#{k}/storage") do |v_ohai, v_api, error_msg|
        expect(v_ohai).to eql(v_api), error_msg
      end
    end
  end
end
