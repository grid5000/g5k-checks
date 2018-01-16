describe "Clock" do

  #TODO update this test, ntpdate is deprecated and should be replaced by ntpd --....
  it "should have the correct hardware clock" do
    %x{/etc/init.d/ntp stop;/usr/sbin/ntpdate ntp;/etc/init.d/ntp start}
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
