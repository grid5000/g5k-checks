describe "Clock" do

  it "should be in sync with hardware clock" do
    hwdate = %x{date -d "`/sbin/hwclock --utc`" +"%s"}
    osdate = %x{date -u +"%s"}
    if (hwdate.to_i - osdate.to_i).abs > 1
      res = system("/sbin/hwclock --systohc")
      Utils.test(res, true, "clock in sync", true) do |v_system, v_api, error_msg|
        expect(v_system).to eql(true), error_msg
      end
    end
  end

end
