# frozen_string_literal: true

describe 'MountPoint' do
  RSpec.configuration.node.get_wanted_mountpoint.each do |m|
    it 'should have the correct mount point' do
      line = Utils.mount_grep(m)
      Utils.test(line, 0, 'mount point exists', true) do |v_system, v_api, error_msg|
        expect(v_system).not_to eql(v_api), error_msg
      end
    end
  end

  Utils.fstab.reject { |_key, value| value['fs_type'] == 'swap' }.each do |_k, v|
    it 'should be mounted' do
      type_fstab = Utils.mount_grep(v['file_system'])
      Utils.test(type_fstab, 0, "#{v['file_system']} mounted", true) do |v_system, v_api, error_msg|
        expect(v_system).not_to eql(v_api), error_msg
      end
    end
  end
end
