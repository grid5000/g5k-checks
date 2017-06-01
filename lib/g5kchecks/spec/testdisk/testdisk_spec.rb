
require 'g5kchecks/utils/utils'

describe "TestDisk" do

  before(:all) do
    tmpapi = RSpec.configuration.node.api_description["storage_devices"]
    if tmpapi != nil
      @api = {}
      tmpapi.each{ |d|
        @api[d["device"]] = d
      }
    end
  end

  RSpec.configuration.node.ohai_description["block_device"].select { |key,value| key =~ /[sh]da/ and value["model"] != "vmDisk" }.each { |k,v|

    it "should give good results in read" do
      stdout = Utils.shell_out("fio #{File.dirname(__FILE__) + "/../../data/read.fio"}").stdout
      stdout.each_line do |line|
        if line =~ /READ/
          maxt_read = Hash[line.split(',').collect!{|s| s.strip.split('=')}]['maxt'].scan(/\d+/)[0].to_i
          maxt_read_api = 0
          maxt_read_api = @api[k]["timeread"].to_i if (@api and @api[k] and @api[k]["timeread"])
	  err = (maxt_read-maxt_read_api).abs
	  expected =  maxt_read_api/10
          expect(err).to be < expected, "#{maxt_read}, #{maxt_read_api}, storage_devices, #{k}, timeread"
        end
      end
    end
  
    it "should give good results in write" do
      stdout = Utils.shell_out("fio #{File.dirname(__FILE__) + "/../../data/write.fio"}").stdout
      stdout.each_line do |line|
        if line =~ /WRITE/
          maxt_write = Hash[line.split(',').collect!{|s| s.strip.split('=')}]['maxt'].scan(/\d+/)[0].to_i
          maxt_write_api = 0
          maxt_write_api = @api[k]["timewrite"].to_i if (@api and @api[k] and @api[k]["timewrite"])
       	  err = (maxt_write-maxt_write_api).abs
	  expected =  maxt_write_api/10
     	  expect(err).to be < expected, "#{maxt_write}, #{maxt_write_api}, storage_devices, #{k}, timewrite"
        end
      end
    end

  }

end
