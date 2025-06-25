Vagrant.configure("2") do |config|
  NUM_WORKERS = 2
  CTRL_NAME = "ctrl"
  NODE_PREFIX = "node-"
  # Using the original LABELS structure helps maintain consistent IP assignment
  # if ctrl is expected to be the first VM (index 0 for IP calculation).
  LABELS = [CTRL_NAME] + (1..NUM_WORKERS).map { |i| "#{NODE_PREFIX}#{i}" }

  # Global settings to improve performance
  config.vm.box = "bento/ubuntu-24.04"
  config.vm.box_check_update = false
  config.ssh.insert_key = false

  # Increase SSH timeout settings
  config.vm.boot_timeout = 600
  config.ssh.connect_timeout = 30
  config.ssh.keep_alive = true

  # Helper method for configuring Ansible provisioners consistently
  def configure_ansible_provisioner(ansible, playbook_path, current_vm_name, current_vm_ip, limit_target = nil)
    ansible.compatibility_mode = "2.0"
    ansible.playbook = playbook_path
    ansible.inventory_path = "ansible/inventory/inventory.cfg"
    ansible.extra_vars = {
      "node_name" => current_vm_name,
      "private_ip" => current_vm_ip
    }
    ansible.limit = limit_target if limit_target # Apply --limit if a target is specified
    # ansible.verbose = "v"
  end

  LABELS.each_with_index do |name, i|
    config.vm.define name do |machine|
      machine.vm.hostname = name
      ip = "192.168.56.#{100 + i}" # IP assignment based on order in LABELS
      machine.vm.network "private_network", ip: ip

      machine.vm.synced_folder "./shared", "/mnt/shared", create: true

      # Configure resources
      machine.vm.provider "virtualbox" do |vb|
        vb.name = name
        vb.memory = name == CTRL_NAME ? 4096 : 6144
        vb.cpus = 2
        vb.check_guest_additions = false
        vb.gui = false

        # Performance optimizations
        vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
        vb.customize ["modifyvm", :id, "--natdnsproxy1", "on"]
        vb.customize ["modifyvm", :id, "--ioapic", "on"]
        vb.customize ["modifyvm", :id, "--nictype1", "virtio"]
      end

      # Configure VM with minimal changes before SSH (faster boot)
      machine.vm.provision "shell", inline: "echo 'Accelerating boot process...'"

      # Provisioning Step 1: General setup for the current VM
      # Vagrant will attempt to run this stage in parallel for all VMs during `vagrant up`.
      machine.vm.provision "ansible_general_setup", type: :ansible do |ansible|
        configure_ansible_provisioner(
          ansible,
          "ansible/playbooks/general.yaml",
          name,
          ip
        )
      end

      # Provisioning Step 2: Specific setup based on VM role
      if name == CTRL_NAME
        # Step 2a: Controller-specific playbook
        machine.vm.provision "ansible_ctrl_specific_setup", type: :ansible do |ansible|
          configure_ansible_provisioner(
            ansible,
            "ansible/playbooks/ctrl.yaml",
            name,
            ip
          )
        end

        # Provisioning Step 3: Finalization playbook for the controller
        # This is defined as the last provisioner for 'ctrl'.
        # Note: For strict "after nodes complete node.yaml" sequencing, see explanation below.
        machine.vm.provision "ansible_ctrl_finalization", type: :ansible do |ansible|
          configure_ansible_provisioner(
            ansible,
            "ansible/playbooks/finalization.yml",
            name,
            ip,
            CTRL_NAME
          ) # Ensures --limit=ctrl is applied
        end
      else # This is a node VM (e.g., node-1, node-2)
        # Step 2b: Node-specific playbook
        # This runs after general.yaml for this node. If multiple nodes are brought up
        # by `vagrant up` concurrently, this step will also run concurrently for them.
        # Note: For strict "after ctrl completes ctrl.yaml" sequencing, see explanation below.
        machine.vm.provision "ansible_node_specific_setup", type: :ansible do |ansible|
          configure_ansible_provisioner(
            ansible,
            "ansible/playbooks/node.yaml",
            name,
            ip
          )
        end
      end
    end
  end
end