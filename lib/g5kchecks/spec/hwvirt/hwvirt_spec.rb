# frozen_string_literal: true

describe 'Virtual Hardware' do
  before do
    @api = RSpec.configuration.node.api_description['supported_job_types']
    @system = RSpec.configuration.node.ohai_description
  end

  it 'should have the good driver' do
    case @system[:kernel][:machine]
    when 'x86_64'
      vhw_type = @system[:cpu][:'0'][:flags].select do |i|
        i == 'svm' || i == 'vmx'
      end
      kmod = ''
      @mod_name = ''
      if vhw_type[0] == 'svm'
        kmod = 'amd-v'
        @mod_name = 'kvm_amd'
      elsif vhw_type[0] == 'vmx'
        kmod = 'ivt'
        @mod_name = 'kvm_intel'
      else
        kmod = false
      end
    when 'aarch64'
      if @system[:cpu][:model] == 'ThunderX2'
        # Apparently, all aarch64 CPU's supports virtualization, and there is
        # not a kernel module for that, so we put arm64
        kmod = 'arm64'
      end
    end

    kmod_api = ''
    kmod_api = @api['virtual'] if @api
    Utils.test(kmod, kmod_api, 'supported_job_types/virtual') do |v_ohai, v_api, error_msg|
      expect(v_ohai).to eql(v_api), error_msg
    end

    if (kmod.class == String) && !vhw_type.nil?
      # rmmod.empty? if the loaded module (for testing) must be removed afterwards.
      rmmod = `PATH=/usr/sbin:/sbin:$PATH lsmod | grep -E -e "^kvm_(amd|intel)"`
      res = system("PATH=/usr/sbin:/sbin:$PATH modprobe #{@mod_name}")
      Utils.test(res, true, 'kvm driver', true) do |v_system, v_api, error_msg|
        expect(v_system).to eql(v_api), error_msg
      end
      system("PATH=/usr/sbin:/sbin:$PATH modprobe -rf #{@mod_name}") if rmmod.empty?
    end
  end
end
