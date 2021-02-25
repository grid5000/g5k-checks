# frozen_string_literal: true

describe 'Systemctl' do
  it 'failed units should be empty' do
    # While there is activating state services (excepting oar-node.service)
    activating_services_number = 2
    while activating_services_number > 1
      activating_services_number = Utils.shell_out('systemctl list-units --all --type=service --state=activating').stdout.split("\n").grep(/loaded units listed/).first.split(' ')[0].to_i
      sleep(0.5) # sleep half a second
    end
    # Get failed units number
    failed_units_number = Utils.shell_out('systemctl --failed').stdout.split("\n").grep(/loaded units listed/).first.split(' ')[0]
    # If failed unit(s), get failed units name(s)
    if failed_units_number == '0'
      failed_units = ''
    else
      failed_units = Utils.shell_out('systemctl --failed').stdout.split(' ').grep(/.service/).join(' ')
    end
    Utils.test(failed_units_number, '0', 'Failed units : ' + failed_units + ' ', true) do |v_system, v_api, error_msg|
      expect(v_system).to eql(v_api), error_msg
    end
  end
end
