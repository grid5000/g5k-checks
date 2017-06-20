
describe "Rights on /tmp" do

  it "should have mode 41777" do
    tmp_mode = File.stat("/tmp").mode.to_s(8)
    Utils.test(tmp_mode, "41777", "/tmp mode", true) do |v_system, v_api, error_msg|
      expect(v_system).to eql(v_api), error_msg
    end
  end
end

describe "Sudo rights" do
  it "should not use sudo-g5k" do
    exist = File.exist?("/etc/sudoers.d/allowed_by_g5ksudo")
    Utils.test(exist, false, "User used sudo-g5k", true) do |v_system, v_api, error_msg|
      expect(v_system).to eql(v_api), error_msg
    end
  end
end
