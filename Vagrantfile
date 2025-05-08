Vagrant.configure("2") do |config|
    NUM_WORKERS = 3 
  
    # Define controller node
    config.vm.define "ctrl" do |ctrl|
      ctrl.vm.box = "bento/ubuntu-24.04"
      ctrl.vm.hostname = "ctrl"
      ctrl.vm.network "private_network", ip: "192.168.56.100"
  
      ctrl.vm.provider "virtualbox" do |vb|
        vb.memory = 4096
        vb.cpus = 1
      end
    end
  
    # Define worker nodes 
    (1..NUM_WORKERS).each do |i|
      config.vm.define "node-#{i}" do |node|
        node.vm.box = "bento/ubuntu-24.04"
        node.vm.hostname = "node-#{i}"
        node.vm.network "private_network", ip: "192.168.56.#{100 + i}"
  
        node.vm.provider "virtualbox" do |vb|
          vb.memory = 6144
          vb.cpus = 2
        end
      end
    end
  end
  