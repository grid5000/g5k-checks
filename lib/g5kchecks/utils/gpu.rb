# frozen_string_literal: true

require 'open3'
require 'json'
require 'yaml'
require 'rexml/document'

module Grid5000
  # Class helping to detect the list of Nvidia devices on a node
  class NvidiaGpu
    NVIDIA_DRIVER_MAJOR_MODE = 195

    def detect_numa_node(complete_pci_bus_id)
      cmd = 'cat /sys/class/pci_bus/' + complete_pci_bus_id.downcase + '/device/numa_node '
      numa_node = nil
      Open3.popen2(cmd) do |_stdin, stdout, _wait_thr|
        stdout.each do |line|
          numa_node = line.strip
        end
      end
      numa_node
    end

    def detect_gpu_file_device(minor_number)
      cmd = 'ls -lha /dev/nvidia[0-9]*'
      device_file_path = nil
      Open3.popen2(cmd) do |_stdin, stdout, _wait_thr|
        stdout.each do |line|
          device_file_path = %r{/dev.*}.match(line).to_s if line =~ /#{NVIDIA_DRIVER_MAJOR_MODE},\s+#{minor_number}/
        end
      end
      device_file_path
    end

    def get_cpu_from_numa_node(numa_node)
      cmd = "lscpu -e=node,socket|grep ^#{numa_node}|sort -u"
      cpu = nil
      Open3.popen2(cmd) do |_stdin, stdout, _wait_thr|
        stdout.each do |line|
          cpu = line.match(/^.*\s+(\d+)$/).captures[0] if line =~ /#{numa_node}\s+\d+/
        end
      end
      cpu
    end

    def fetch_nvidia_cards_info
      cmd = 'nvidia-smi -q -x'
      cards = []
      names = []
      _, stdout, _stderr, wait_thr = Open3.popen3(cmd)
      lines = stdout.readlines
      exit_status = wait_thr.value
      if exit_status == 0
        xml = REXML::Document.new(lines.join)
        xml.elements.each('*/gpu') do |gpu|
          device_file_path = detect_gpu_file_device(gpu.elements['minor_number'].text)
          device_name = device_file_path.split('/')[-1]
          names << device_name.to_sym
          card = {}
          card[:vendor] = 'Nvidia'
          card[:model] = gpu.elements['product_name'].text
          card[:vbios_version] = gpu.elements['vbios_version'].text
          card[:power_default_limit] = gpu.elements['power_readings'].elements['default_power_limit'].text
          mem = gpu.elements['fb_memory_usage'].elements['total'].text.split(' ')[0].to_i * 1_000_000
          card[:memory] = mem
          card[:device] = device_file_path
          bus = gpu.attributes['id'].split(':')
          prefix_bus = bus[0].gsub(/^.*([0-9A-z]{4})$/, '\1')
          bus_id = bus[1]
          complete_pci_bus_id = prefix_bus + ':' + bus_id
          card[:cpu_affinity] = get_cpu_from_numa_node(detect_numa_node(complete_pci_bus_id))
          cards << card
        end
        Hash[names.zip(cards)]
      else
        {}
      end
    rescue Errno::ENOENT
      {}
    end

    def get_json
      fetch_nvidia_cards_info.to_json
    end

    def get_yaml
      fetch_nvidia_cards_info.to_yaml
    end
  end
end

# To test the above class in command line
if $PROGRAM_NAME == __FILE__
  cards = Grid5000::NvidiaGpu.new
  puts cards.get_json
end
