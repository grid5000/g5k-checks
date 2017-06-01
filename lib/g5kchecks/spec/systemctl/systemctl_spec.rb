describe "Systemctl" do
  it "status should be running" do

    stdout, stderr, status = Open3.capture3('systemctl is-system-running')

    stdout.strip!
    expect(stdout).to eql('running'), "systemctl status should be 'running' (is: '#{stdout}')"
  end
end
