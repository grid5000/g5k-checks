# frozen_string_literal: true

require 'json'
require 'nokogiri'

require 'g5kchecks/utils/utils'


Ohai.plugin(:Gpu) do
  provides 'gpu_devices'
  include Utils::Mixin

  def detect_numa_node(complete_pci_bus_id)
    fileread("/sys/class/pci_bus/#{complete_pci_bus_id.downcase}/device/numa_node")
  end

  def get_cpu_from_numa_node(numa_node)
    cmd = "lscpu -e=node,socket"
    cpu = nil
    shell_output = shell_out(cmd)
    shell_output.stdout.each_line.uniq do |line|
      cpu = line.match(/^.*\s*(\d+)$/).captures[0] if /#{numa_node}\s+\d+/.match?(line)
    end
    cpu
  end

  
  def fetch_amdgpu_cards_info
    cmd = 'rocm-smi -a --json'
    cards = {}
    shell_output = shell_out(cmd)
    # Do not check return code as rocm-smi may return non zero values with valid output
    return {} if shell_output.stdout == ""
    gpus = JSON.parse(shell_output.stdout)
    gpus.each do |gpu_id, gpu|
      next if gpu_id == "system"
      card = {}
      card[:vendor] = 'AMD'
      card[:model] = gpu['Card series']
      # "Card Series" may be used on other systems
      if card[:model].to_s.empty? then
        card[:model] = gpu['Card Series']
      end
      # Workaround for incomplete model name from rocm-smi (ROCm 4.5/debian11)
      if card[:model] == "deon Instinct MI50 32GB"
        card[:model] = "Radeon Instinct MI50 32GB"
      end
      card[:vbios_version] = gpu['VBIOS version']
      card[:power_default_limit] = gpu['Max Graphics Package Power (W)']
      card[:memory] = case card[:model]
                      when "Radeon Instinct MI50 32GB"
                        32*(1024**3)
                      when "AMD Instinct MI300X"
                        192*(1024**3)
                      when "Instinct MI210"
                        64*(1024**3)
                      else
                        raise "g5kchecks does not supports this AMD GPU #{card[:model]}"
                      end
      card[:device] = "/dev/dri/#{gpu_id}"
      bus = gpu['PCI Bus'].split(':')[0..1].join(':').downcase
      numa_node = detect_numa_node(bus)
      # Workaround for #13587
      if numa_node == "-1"
        numa_node = "0"
      end
      card[:cpu_affinity] = get_cpu_from_numa_node(numa_node)
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
  
  def detect_nvidia_gpu_file_device(minor_number, major_mode = 195)
    cmd = 'ls -lha /dev/nvidia[0-9]*'
    device_file_path = nil
    shell_output = shell_out(cmd)
    shell_output.stdout.each_line do |line|
      device_file_path = %r{/dev.*}.match(line).to_s if /#{major_mode},\s+#{minor_number}/.match?(line)
    end
    device_file_path
  end

  def fetch_nvidia_cards_info
    cmd = 'nvidia-smi -q -x'
    cards = []
    names = []
    shell_output = shell_out(cmd)
    stdout = shell_output.stdout
    if shell_output.exitstatus == 0
      xml = Nokogiri::XML(stdout)
      xml.css('gpu').each do |gpu|
        device_file_path = detect_nvidia_gpu_file_device(gpu.css('minor_number').text)
        device_name = device_file_path.split('/')[-1]
        names << device_name.to_sym
        card = {}
        card[:vendor] = 'Nvidia'
        # It's important to use 'gsub' and not 'gsub!' here since the presence
        # of 'NVIDIA ' in front of the product name depends both on the model
        # and the version of nvidia-smi, and 'gsub!' may return nil.
        card[:model] = gpu.css('product_name').text.gsub(/^NVIDIA /, '')
        card[:vbios_version] = gpu.css('vbios_version').text
        power_xml_node = gpu.css('power_readings')
        if power_xml_node.empty?
          # Driver 535 reports the reading under 'gpu_power_readings'
          power_xml_node = gpu.css('gpu_power_readings')
        end
        card[:power_default_limit] = power_xml_node.css('default_power_limit').text
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

  collect_data do
    cards = fetch_nvidia_cards_info
    cards.merge!(fetch_amdgpu_cards_info)
    gpu_devices Mash.new(cards)
    gpu_devices
  end
end
