describe "Systemctl" do

  it "status should be running" do
    stdout = Utils.shell_out('systemctl is-system-running').stdout
    stdout.strip!
    expect(stdout).to eql('running'), "systemctl status should be 'running' (is: '#{stdout}')"
  end
end
