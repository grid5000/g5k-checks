# frozen_string_literal: true

describe 'MountPoint' do
  RSpec.configuration.node.get_wanted_mountpoint.each do |m|
    it 'should have the correct mount point' do
      line_mount = Utils.mount_filter(m, :dest)
      Utils.test(line_mount, 1, 'mount point exists', true) do |v_system, v_api, error_msg|
        expect(v_system).not_to eql(v_api), error_msg
      end
    end
  end

  swap_list = Utils.swap_list
  Utils.fstab.each_value do |v|
    it 'should be mounted' do
      message = "#{v['file_system']} not mounted (type #{v['fs_type']} on #{v['mount_point']})"
      nb_mount = if v['fs_type'] == 'swap'
                   swap_list.include?(v['file_system']) ? 1 : 0
                 else
                   message += ', or mounted more than once'
                   Utils.mount_filter(v['file_system'], :source).length
                 end

      Utils.test(nb_mount, 1, message, true) do |v_system, v_api, error_msg|
        expect(v_system).to eql(v_api), error_msg
      end
    end
  end
end
