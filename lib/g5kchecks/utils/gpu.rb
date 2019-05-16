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
      Open3.popen2(cmd) do |stdin, stdout, wait_thr|
        stdout.each do | line |
          numa_node = line.strip
        end
      end
      return numa_node
    end

    def detect_gpu_file_device(minor_number)
      cmd = 'ls -lha /dev/nvidia[0-9]*'
      device_file_path = nil
      Open3.popen2(cmd) do |stdin, stdout, wait_thr|
        stdout.each do | line |
          if line =~ /#{NVIDIA_DRIVER_MAJOR_MODE},\s+#{minor_number}/
            device_file_path = /\/dev.*/.match(line).to_s
          end
        end
      end
      return device_file_path
    end

    def fetch_nvidia_cards_info()
      begin
        cmd = 'nvidia-smi -q -x'
        cards = []
        names = []
        _, stdout, stderr, wait_thr = Open3.popen3(cmd)
        lines = stdout.readlines
        exit_status = wait_thr.value
        if exit_status == 0
          xml = REXML::Document.new(lines.join)
          xml.elements.each('*/gpu') { |gpu|
            device_file_path = detect_gpu_file_device(gpu.elements['minor_number'].text)
            device_name = device_file_path.split('/')[-1]
            names << device_name.to_sym
            card = {}
            card[:vendor] = 'Nvidia'
            card[:model] = gpu.elements['product_name'].text
            card[:vbios_version] = gpu.elements['vbios_version'].text
            card[:power_default_limit] = gpu.elements['power_readings'].elements['default_power_limit'].text
            mem = gpu.elements['fb_memory_usage'].elements['total'].text.split(' ')[0].to_i*1000000
            card[:memory] = mem
            card[:device] = device_file_path
            bus = gpu.attributes['id'].split(':')
            prefix_bus = bus[0]
            if prefix_bus.to_i == 0
              prefix_bus = '0000'
            end
            bus_id = bus[1]
            complete_pci_bus_id = prefix_bus + ':' + bus_id
            card[:cpu_affinity] = detect_numa_node(complete_pci_bus_id)
            cards << card
          }
          return Hash[names.zip(cards)]
	else
	  return {}
        end
      rescue Errno::ENOENT
        raise 'nvidia-smi not found'
      end
    end

    def get_json()
      fetch_nvidia_cards_info().to_json()
    end

    def get_yaml()
      fetch_nvidia_cards_info().to_yaml()
    end
  end
end

# To test the above class in command line
if $PROGRAM_NAME == __FILE__
  cards = Grid5000::NvidiaGpu.new
  puts cards.get_json()
end
