Vagrant.configure("2") do |config|
  NUM_WORKERS = 2
  LABELS = ["ctrl"] + (1..NUM_WORKERS).map { |i| "node-#{i}" }

  LABELS.each_with_index do |name, i|
    config.vm.define name do |machine|
      machine.vm.box = "bento/ubuntu-24.04"
      machine.vm.hostname = name
      ip = "192.168.56.#{100 + i}"
      machine.vm.network "private_network", ip: ip

      # Configure resources
      machine.vm.provider "virtualbox" do |vb|
        vb.name = name
        vb.memory = name == "ctrl" ? 4096 : 6144
        vb.cpus = 2
      end

      # First: general setup playbook (runs on all VMs)
      machine.vm.provision :ansible do |ansible|
        ansible.compatibility_mode = "2.0"
        ansible.playbook = "ansible/playbooks/general.yaml"
        ansible.inventory_path = "ansible/inventory/inventory.cfg"
        ansible.extra_vars = {
          "node_name" => name,
          "private_ip" => ip
        }
      end

      # Second: controller or node specific setup
      machine.vm.provision :ansible do |ansible|
        ansible.compatibility_mode = "2.0"
        ansible.playbook = name == "ctrl" ? "ansible/playbooks/ctrl.yaml" : "ansible/playbooks/node.yaml"
        ansible.inventory_path = "ansible/inventory/inventory.cfg"
        ansible.extra_vars = {
          "node_name" => name,
          "private_ip" => ip
        }
      end
    end
  end
end