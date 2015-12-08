# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrant's Ansible Docs: http://docs.vagrantup.com/v2/provisioning/ansible.html
# Vagrant Automatic Inventory File: .vagrant/provisioners/ansible/inventory/vagrant_ansible_inventory
# Vagrant 1.7 auto Private Key Location: .vagrant/machines/[machine name]/[provider]/private_key

# Example Layout: https://github.com/debops/examples/blob/master/vagrant-multi-machine/Vagrantfile

# Config
GUI     = false # Enable/Disable GUI
RAM     = 1024   # Default memory size in MB
DOMAIN  = ".hpcw.com"
NETWORK = "192.168.125."
NETMASK = "255.255.255.0"
BOX     = 'centos71-nocm-0.0.1.box'
HOSTS = {
  "proxy" => [NETWORK+'5', RAM, GUI, BOX ]
  
}

Vagrant.require_version ">= 1.7.0"

VAGRANTFILE_API_VERSION = "2"
Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  
  # Hostmanager Configs
  config.hostmanager.enabled = true             # Enable HostMan Plugin
  config.hostmanager.manage_host = true         # Update Host's host file
  config.hostmanager.ignore_private_ip = false  
  config.hostmanager.include_offline = true
  
  HOSTS.each do | (name, cfg) |
    ipaddr, ram, gui, box = cfg

    config.vm.define name do |machine|
      machine.vm.box     = box
      machine.vm.provider "virtualbox" do |vbox|
        vbox.gui    = gui
        vbox.memory = ram
      end
      machine.vm.hostname = name + DOMAIN
      machine.vm.network 'private_network', ip: ipaddr, netmask: NETMASK
      machine.vm.network "forwarded_port", guest: 80, host: 8080
    end
    # Provisioning
    config.vm.provision "shell", path: "scripts/#{name}/#{name}.sh"
    # config.vm.provision :ansible do |ansible|
    #   ansible.verbose = "v"                         # Tells vagrant to display ansible command used
    #   ansible.playbook = "ansible/#{name}.yml"
    # end
    
  end # HOSTS-each
end