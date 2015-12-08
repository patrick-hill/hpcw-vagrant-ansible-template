#!/usr/bin/env bash

# Pull Source
echo 'Pulling Ansible source...'
git clone git://github.com/ansible/ansible.git --recursive
cd ./ansible

echo 'Sourcing env-setup...'
source ./hacking/env-setup # -q for quiet

# Python Dependency
echo 'Installing pip & then pip install: paramiko PyYAML Jinja2 httplib2 six'
sudo easy_install pip && sudo pip install paramiko PyYAML Jinja2 httplib2 six

# Updating Ansible
echo 'Updating Ansible...'
git pull --rebase
git submodule update --init --recursive

echo 'Ansible installation complete!'
exit 0
