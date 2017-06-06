describe "Clock" do

  #TODO update this test, ntpdate is deprecated and should be replaced by ntpd --....
  it "should have the correct hardware clock" do
    %x{/etc/init.d/ntp stop;/usr/sbin/ntpdate ntp.nancy.grid5000.fr;/etc/init.d/ntp start}
    hwdate = %x{date -d "`/sbin/hwclock --utc`" +"%s"}
    osdate = %x{date -u +"%s"}
    if (hwdate.to_i - osdate.to_i).abs > 1
      expect(system( "/sbin/hwclock --systohc")).to eql(true), "clk error"
    end
  end

end
