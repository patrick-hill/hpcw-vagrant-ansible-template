# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrant's Ansible Docs: http://docs.vagrantup.com/v2/provisioning/ansible.html
# Vagrant Automatic Inventory File: .vagrant/provisioners/ansible/inventory/vagrant_ansible_inventory
# Vagrant 1.7 auto Private Key Location: .vagrant/machines/[machine name]/[provider]/private_key
    
Vagrant.require_version ">= 1.7.0"

VAGRANTFILE_API_VERSION = "2"
Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.provider :virtualbox do |v|
    v.gui     = false
    v.name    = 'myVM'
    v.cpu     = '1'
    v.memery  = '1024' 
  end
  
  config.vm.box       = "centos67-nocm-0.0.1.box"
  config.vm.hostname  = "devlocal"

  config.vm.network :private_network, ip: "15.0.0.20"
  config.vm.network :forwarded_port, guest: 80,  host: 8080

  # Provisioning
  config.vm.provision "shell", path: "setup.sh"
  config.vm.provision :ansible do |ansible|
    ansible.verbose = "v"                         # Tells vagrant to display ansible command used
    ansible.playbook = "ansible/playbook.yml"
  end
end