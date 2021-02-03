# frozen_string_literal: true

describe 'Systemctl' do
  it 'failed units should be empty' do
     # While there is activating state services (excepting oar-node.service)
     activating_services_number = 2
     while activating_services_number > 1
       activating_services_number = Utils.shell_out('systemctl list-units --all --type=service --state=activating').stdout.split("\n").grep(/loaded units listed/).first.split(' ')[0].to_i
       sleep(0.5) # sleep half a second
     end
     # Test failed units
    stdout = Utils.shell_out('systemctl --failed').stdout.split("\n").grep(/loaded units listed/).first.split(' ')[0]
    Utils.test(stdout, '0', 'systemctl failed units', true) do |v_system, v_api, error_msg|
      expect(v_system).to eql(v_api), error_msg
    end
  end
end
