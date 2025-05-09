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
        vb.cpus = name == "ctrl" ? 1 : 2
      end

      # Ansible Provisioner
      machine.vm.provision :ansible do |ansible|
        ansible.compatibility_mode = "2.0"
        ansible.playbook = case name
          when "ctrl" then "ctrl.yaml"
          else "node.yaml"
        end
        ansible.extra_vars = {
          "node_name" => name,
          "private_ip" => ip
        }
        ansible.inventory_path = "inventory.cfg"
      end
    end
  end

   # Shared SSH keys folder for Ansible to access
  config.vm.synced_folder "./ssh_keys", "/vagrant/ssh_keys"
  
  # Shared General Playbook 
  config.vm.provision "ansible_local" do |ansible|
    ansible.playbook = "general.yaml"
  end
end
