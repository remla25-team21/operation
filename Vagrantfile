Vagrant.configure("2") do |config|
    NUM_WORKERS = 2

    # Base
    config.vm.box = "bento/ubuntu-24.04"
    config.vm.box_version = "202502.21.0"
  
    # Controller node
    config.vm.define "ctrl" do |ctrl|
      ctrl.vm.hostname = "ctrl"
      ctrl.vm.network "private_network", ip: "192.168.56.100"
  
      ctrl.vm.provider "virtualbox" do |vb|
        vb.name = "k8s-ctrl"
        vb.memory = 4096
        vb.cpus = 1
      end
  
      ctrl.vm.provision :ansible do |a|
        a.compatibility_mode = "2.0"
        a.playbook = "ctrl.yml"
      end
    end
  
    # Worker nodes
    (1..NUM_WORKERS).each do |i|
      config.vm.define "node-#{i}" do |node|
        node.vm.hostname = "node-#{i}"
        node.vm.network "private_network", ip: "192.168.56.#{100 + i}"
  
        node.vm.provider "virtualbox" do |vb|
          vb.name = "k8s-node-#{i}"
          vb.memory = 6144
          vb.cpus = 2
        end
  
        node.vm.provision :ansible do |a|
          a.compatibility_mode = "2.0"
          a.playbook = "node.yml"
        end
      end
    end
  end
  