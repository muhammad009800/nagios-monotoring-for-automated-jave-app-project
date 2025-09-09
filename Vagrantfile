
Vagrant.configure("2") do |config|
  config.hostmanager.enabled = true 
  config.hostmanager.manage_host = true
  config.vbguest.auto_update = false






### build atrifact vm  ####
  config.vm.define "mavin" do |mavin|
    mavin.vm.box = "ubuntu/jammy64"
    mavin.vm.hostname = "mavin"
    mavin.vm.provision "shell", path: "maven.sh"
    mavin.vm.network "private_network", ip: "192.168.56.13"
    mavin.vm.provider "virtualbox" do |vb|
      vb.memory = "1024"
    end
  end


### tomcat vm  ####
  config.vm.define "app01" do |app01|
    app01.vm.box = "eurolinux-vagrant/centos-stream-9"
    app01.vm.box_version = "9.0.43"
    app01.vm.hostname = "app01"
    app01.vm.network "private_network", ip: "192.168.56.15"
    app01.vm.provision "shell", path: "app01.sh"
    app01.vm.provider "virtualbox" do |vb|
      vb.memory = "6144"
   end
end
### DB vm  ####
config.vm.define "db01" do |db01|
  db01.vm.box = "eurolinux-vagrant/centos-stream-9"
  db01.vm.box_version = "9.0.43"
  db01.vm.hostname = "db01"
  db01.vm.provision "shell", path: "db01.sh"
  db01.vm.network "private_network", ip: "192.168.56.14"
  db01.vm.provider "virtualbox" do |vb|
    vb.memory = "2048"
  end
end


### memcache  vm  ####
  config.vm.define "mc01" do |mc01|
    mc01.vm.box = "eurolinux-vagrant/centos-stream-9"
    mc01.vm.box_version = "9.0.43"
    mc01.vm.hostname = "mc01"
    mc01.vm.network "private_network", ip: "192.168.56.12"
    mc01.vm.provision "shell", path: "mc01.sh"
    mc01.vm.provider "virtualbox" do |vb|
      vb.memory = "1024"
    end
  end

### rabbit mq vm  ####
  config.vm.define "rmq01" do |rmq01|
    rmq01.vm.box = "eurolinux-vagrant/centos-stream-9"
    rmq01.vm.box_version = "9.0.43"
    rmq01.vm.hostname = "rmq01"
    rmq01.vm.network "private_network", ip: "192.168.56.11"
    #rmq01.vm.provision "shell", path: "rmq01.sh"
    rmq01.vm.provision "shell", path: "nagios_nrpe_centos_clint.sh"
    rmq01.vm.provider "virtualbox" do |vb|
      vb.memory = "1024"
    end
  end

### web01 vm  ####
  config.vm.define "web01" do |web01|
    web01.vm.box = "ubuntu/jammy64"
    web01.vm.hostname = "web01"
    #web01.vm.provision "shell", path: "web01.sh"
    web01.vm.provision "shell", path: "nagios_nrpe_ubuntu_clint.sh"
    web01.vm.network "private_network", ip: "192.168.56.10"
    web01.vm.provider "virtualbox" do |vb|
      vb.memory = "1024"
    end
  end

  config.vm.define "nagios" do |nagios|
    nagios.vm.box = "eurolinux-vagrant/centos-stream-9"
    nagios.vm.box_version = "9.0.43"  
    nagios.vm.hostname = "nagios"
    nagios.vm.provision "shell", path: "prov_nagios.sh"
    nagios.vm.network "private_network", ip: "192.168.56.16"
    nagios.vm.provider "virtualbox" do |vb|
      vb.memory = "1024"
    end
  end


end

=begin   vm example

### DB vm  ####
  config.vm.define "db01" do |db01|
    db01.vm.box = ""
    db01.vm.box_version = ""
    db01.vm.hostname = "db01"
    db01.vm.network "private_network", ip: "192.168.56.15"
    db01.vm.provider "virtualbox" do |vb|
      vb.memory = ""
 end

=end




=begin  commment area

   config.vm.box_check_update = false
   config.vm.network "forwarded_port", guest: 80, host: 8080
   config.vm.network "forwarded_port", guest: 80, host: 8080, host_ip: "127.0.0.1"
   config.vm.network "private_network", ip: "192.168.33.10"
   config.vm.network "public_network"
   config.vm.synced_folder "../data", "/vagrant_data"
   config.vm.synced_folder ".", "/vagrant", disabled: true
   config.vm.provider "virtualbox" do |vb|
      Display the VirtualBox GUI when booting the machine
     vb.gui = true
  
      Customize the amount of memory on the VM:
     vb.memory = "1024"
   end

   config.vm.provision "shell", inline: <<-SHELL
     apt-get update
     apt-get install -y apache2
   SHELL

=end
