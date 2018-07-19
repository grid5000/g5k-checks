
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
      test_file = File.expand_path("../../data/read.fio", File.dirname(__FILE__))
      stdout = Utils.shell_out("fio #{test_file}").stdout
      stdout.each_line do |line|
        if line =~ /READ/
          maxt_read = Hash[line.split(',').collect!{|s| s.strip.split('=')}]['maxt'].scan(/\d+/)[0].to_i
          maxt_read_api = 0
          maxt_read_api = @api[k]["timeread"].to_i if (@api and @api[k] and @api[k]["timeread"])
	  err = (maxt_read-maxt_read_api).abs
	  expected =  maxt_read_api/10
          Utils.test(err, expected, "storage_devices/#{k}/timeread", true) do |v_system, v_api, error_msg|
            expect(v_system).to be < v_api, error_msg
          end
        end
      end
    end
  
    it "should give good results in write" do
      test_file = File.expand_path("../../data/write.fio", File.dirname(__FILE__))
      stdout = Utils.shell_out("fio #{test_file}").stdout
      stdout.each_line do |line|
        if line =~ /WRITE/
          maxt_write = Hash[line.split(',').collect!{|s| s.strip.split('=')}]['maxt'].scan(/\d+/)[0].to_i
          maxt_write_api = 0
          maxt_write_api = @api[k]["timewrite"].to_i if (@api and @api[k] and @api[k]["timewrite"])
       	  err = (maxt_write-maxt_write_api).abs
	  expected =  maxt_write_api/10
          Utils.test(err, expected, "storage_devices/#{k}/timewrite", true) do |v_system, v_api, error_msg|
            expect(v_system).to be < v_api, error_msg
          end
        end
      end
    end
  }

end
