# frozen_string_literal: true

require 'g5kchecks/utils/utils'

describe 'TestDisk' do
  before(:all) do
    tmpapi = RSpec.configuration.node.api_description['storage_devices']
    unless tmpapi.nil?
      @api = {}
      tmpapi.each do |d|
        @api[d['device']] = d
      end
    end
  end

  RSpec.configuration.node.ohai_description['block_device'].select { |key, value| key =~ /[sh]da/ && (value['model'] != 'vmDisk') }.each do |k, _v|
    maxt_read_api = 0
    maxt_read_api = @api[k]['timeread'].to_i if @api && @api[k] && @api[k]['timeread']
    if maxt_read_api != 0

      it 'should give good results in read' do
        test_file = File.expand_path('../../data/read.fio', File.dirname(__FILE__))
        stdout = Utils.shell_out("fio #{test_file}").stdout
        stdout.each_line do |line|
          next unless /READ/.match?(line)

          maxt_read = Hash[line.split(',').collect! { |s| s.strip.split('=') }]['maxt'].scan(/\d+/)[0].to_i
          err = (maxt_read - maxt_read_api).abs
          expected = maxt_read_api / 10
          Utils.test(err, expected, "storage_devices/#{k}/timeread", true) do |v_system, v_api, error_msg|
            expect(v_system).to be < v_api, error_msg
          end
        end
      end

    end

    maxt_write_api = 0
    maxt_write_api = @api[k]['timewrite'].to_i if @api && @api[k] && @api[k]['timewrite']

    next unless maxt_write_api != 0

    it 'should give good results in write' do
      test_file = File.expand_path('../../data/write.fio', File.dirname(__FILE__))
      stdout = Utils.shell_out("fio #{test_file}").stdout
      stdout.each_line do |line|
        next unless /WRITE/.match?(line)

        maxt_write = Hash[line.split(',').collect! { |s| s.strip.split('=') }]['maxt'].scan(/\d+/)[0].to_i
        err = (maxt_write - maxt_write_api).abs
        expected = maxt_write_api / 10
        Utils.test(err, expected, "storage_devices/#{k}/timewrite", true) do |v_system, v_api, error_msg|
          expect(v_system).to be < v_api, error_msg
        end
      end
    end
  end
end
