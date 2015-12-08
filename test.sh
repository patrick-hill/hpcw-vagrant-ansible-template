#!/usr/bin/env bash

# This script will prep the host from the ground up for this project
replace_config=1
replace_roles=1

# Install Ansible
installed=$(which ansible && echo $?)
if [ installed == '1' ]; then
	brew install ansible
fi

# Template ansible.cfg
if [ $replace_config == 1]; then
	if [ ! -e 'ansible.cfg' ]; then
		# Remove ansible.cfg
		rm -f ansible.cfg
	fi
	# Download config
	curl -s https://raw.githubusercontent.com/ansible/ansible/devel/examples/ansible.cfg -o ansible.cfg
fi

# Helper for replacing settings in ansible.cfg
sed_replace() {
	sed -i '' "s|.*$1.*|$2|" ansible.cfg
}

# New Settings
sed_replace '#roles_path' 'roles_path = ansible/roles'

# Ansible Galaxy
if [ $replace_roles == 1 ]; then
	if [ ! -d 'ansible/roles' ]; then
		# Remove Ansible Roles
		rm -rf ansible/roles
	fi
	# Download desired Ansible Roles
	
fi


# Check Vagrant Status
vm_stat=$(vagrant status | grep 'default.*running')
if [ vm_stat == '1' ]; then
	vagrant destroy -f
fi

# Start VM
vagrant up --provider=virtualbox

