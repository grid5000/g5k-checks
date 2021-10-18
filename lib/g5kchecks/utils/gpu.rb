# frozen_string_literal: true

require 'json'
require 'yaml'
require 'nokogiri'

module Grid5000

  class Gpu

    def detect_numa_node(complete_pci_bus_id)
      Utils.fileread("/sys/class/pci_bus/#{complete_pci_bus_id.downcase}/device/numa_node")
    end

    def get_cpu_from_numa_node(numa_node)
      cmd = "lscpu -e=node,socket"
      cpu = nil
      shell_out = Utils.shell_out(cmd)
      shell_out.stdout.each_line.uniq do |line|
        cpu = line.match(/^.*\s*(\d+)$/).captures[0] if /#{numa_node}\s+\d+/.match?(line)
      end
      cpu
    end
  end

  # Class helping to detect the list of AMD GPU on a node
  class AmdGpu < Gpu

    def fetch_amdgpu_cards_info
      cmd = 'rocm-smi -a --json'
      cards = {}
      shell_out = Utils.shell_out(cmd)
      # Do not check return code as rocm-smi may return non zero values with valid output
      return {} if shell_out.stdout == ""
      gpus = JSON.parse(shell_out.stdout)
      gpus.each do |gpu_id, gpu|
        next if gpu_id == "system"
        card = {}
        card[:vendor] = 'AMD'
        card[:model] = gpu['Card series']
        card[:vbios_version] = gpu['VBIOS version']
        card[:power_default_limit] = gpu['Max Graphics Package Power (W)']
        card[:memory] = case card[:model]
                        when "Radeon Instinct MI50 32GB"
                          32*(1024**3)
                        else
                          raise "g5kchecks does not supports this AMD GPU #{card[:model]}"
                        end
        card[:device] = "/dev/dri/#{gpu_id}"
        bus = gpu['PCI Bus'].split(':')[0..1].join(':').downcase
        card[:cpu_affinity] = get_cpu_from_numa_node(detect_numa_node(bus))
        cards[gpu_id] = card
      end
      return cards
    rescue Ohai::Exceptions::Exec => e
      if e.message == "No such file or directory - rocm-smi"
        {}
      else
        raise e
      end
    end

    def get_json
      fetch_amdgpu_cards_info.to_json
    end

    def get_yaml
      fetch_amdgpu_cards_info.to_yaml
    end
  end
  # Class helping to detect the list of Nvidia devices on a node
  class NvidiaGpu < Gpu

    NVIDIA_DRIVER_MAJOR_MODE = 195

    def detect_gpu_file_device(minor_number)
      cmd = 'ls -lha /dev/nvidia[0-9]*'
      device_file_path = nil
      shell_out = Utils.shell_out(cmd)
      shell_out.stdout.each_line do |line|
        device_file_path = %r{/dev.*}.match(line).to_s if /#{NVIDIA_DRIVER_MAJOR_MODE},\s+#{minor_number}/.match?(line)
      end
      device_file_path
    end

    def fetch_nvidia_cards_info
      cmd = 'nvidia-smi -q -x'
      cards = []
      names = []
      shell_out = Utils.shell_out(cmd)
      stdout = shell_out.stdout
      if shell_out.exitstatus == 0
        xml = Nokogiri::XML(stdout)
        xml.css('gpu').each do |gpu|
          device_file_path = detect_gpu_file_device(gpu.css('minor_number').text)
          device_name = device_file_path.split('/')[-1]
          names << device_name.to_sym
          card = {}
          card[:vendor] = 'Nvidia'
          card[:model] = gpu.css('product_name').text
          card[:vbios_version] = gpu.css('vbios_version').text
          card[:power_default_limit] = gpu.css('power_readings').css('default_power_limit').text
          mem = gpu.css('fb_memory_usage').css('total').text.split(' ')[0].to_i * 1024 * 1024
          card[:memory] = mem
          card[:device] = device_file_path
          bus = gpu.attribute('id').text.split(':')
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
    rescue StandardError
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
