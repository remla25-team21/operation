Vagrant.configure("2") do |config|
    # Base
    config.vm.box = "bento/ubuntu-24.04"
  
    # Configuration variables
    num_workers = 2
    vm_memory = { "ctrl" => 4096 }.merge((1..num_workers).map { |i| ["node-#{i}", 6144] }.to_h)
    vm_cpus   = { "ctrl" => 1 }.merge((1..num_workers).map { |i| ["node-#{i}", 2] }.to_h)
  
    # Define VMs
    ["ctrl", *(1..num_workers).map { |i| "node-#{i}" }].each_with_index do |name, index|
      config.vm.define name do |node|
        node.vm.hostname = name
        node.vm.network "private_network", ip: "192.168.56.#{100 + index}"
        node.vm.provider "virtualbox" do |vb|
          vb.memory = vm_memory[name]
          vb.cpus = vm_cpus[name]
        end
  
        # Ansible provisioning
        node.vm.provision :ansible do |ansible|
          ansible.compatibility_mode = "2.0"
          ansible.playbook = case name
                             when "ctrl"
                               "ctrl.yaml"
                             when /^node-/
                               "node.yaml"
                             else
                               "general.yaml"
                             end
          ansible.extra_vars = {
            node_name: name,
            worker_count: num_workers
          }
        end
      end
    end
  end
  