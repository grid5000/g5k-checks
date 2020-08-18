# frozen_string_literal: true

describe 'Systemctl' do
  it 'status should be running' do
    stdout = Utils.shell_out('systemctl is-system-running').stdout.strip
    Utils.test(stdout, 'running', 'systemctl status', true) do |v_system, v_api, error_msg|
      expect(v_system).to eql(v_api), error_msg
    end
  end
end
