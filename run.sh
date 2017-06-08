#!/usr/bin/env bash
clear

## Testing line for self updating ;)

#####################################################
#              VARIABLES							#
#####################################################
start=`date +%s`
print_prefix="* * Automaton 9k - run.sh ==>"
dts=`date +%Y-%m-%d_%H:%M:%S`
#####################################################
#              USER CONFIG VARIABLES				#
#####################################################
source run.properties
#####################################################
#              FUNCTIONS CODE BLOCK                 #
#####################################################
script_update() {
  if [ $script_check_updates && script_version_check() ]; then
    if [ script_download_updates() ]; then
      script_prep_update() && script_do_update()
    else 
      print_line "Script: Download Failed. Skipping update..."
    fi # Script_download_updates()
    
    print_line "Script: Version: $script_ver_current is latest"
  fi #script_check_updates && script_version_check()
}

script_version_check() {
  print_line "Script: Checking for updates..."
  script_ver_current=$(grep 'script_version' run.properties | awk -F= '{print $2}')
  script_ver_target=$(curl -s ${script_src_repo}/run.properties | grep script_version | awk -F= '{print $2}')
  # [ "$script_ver_target" -gt "$script_ver_current" ] && return 0 || return 1
  [ "$(version_check $script_ver_current)" -lt "$(version_check $script_ver_target)" ] && return 0 || return 1
}

## each separate version number must be less than 3 digit wide !
function version_check {
  echo "$@" | gawk -F. '{ printf("%03d%03d%03d\n", $1,$2,$3); }';
}

script_download_updates() {
  download_failed=false
  print_line "Script: Downloading updates..."
  if ! curl -s ${script_src_repo}/run.properties -O run.properties.tmp ; then
    download_failed=true
  if ! curl -s ${script_src_repo}/run.sh -O run.sh.tmp ; then
    download_failed=true
  [ $download_failed ] && return 1 || return 0
}

script_prep_update() {
  # Set File Properties
  OCTAL_MODE=$(stat -c '%a' $SELF)
  if [ ! chmod $OCTAL_MODE "$0.tmp" ]; then
    print_line "Script: Failed: Error while trying to set mode on $0.tmp."
  fi
  # Create actual update script
  cat > run.updateScript.sh << EOF
#!/bin/bash
date=`date +%Y-%m-%d_%H-%M-%S`
# Backup current script
if [ mv run.sh "run.sh.${date} && mv "run.sh.tmp" "run.sh" ] ; then
  echo "Script: Update complete! Relaunching..."
  exec /bin/bash "run.sh" "$@" && rm -f run.updateScript.sh
else
  echo "Script: Failed to move script files!"
fi
EOF
}

script_do_update() {
  exec /bin/bash "run.updateScript.sh" "$@"
  exit 1
}

print_line() {
  echo -e "$print_prefix $@"
}

print_done() {
  print_line "#####################################################\n"
}

in_list() {
	[[ $1 =~ $2 ]] && return 0 || return 1	
}

sed_replace() {
	sed -i "s|.*$2.*|$3|" $1
}

vagrant_install() {
  installed=$(which vagrant && echo $?)
  if [ "$installed" == '1' ]; then
    # print_line "Install: Installing ..."
    print_line "Install: Vagrant NOT installed. Auto installation is not yet supported. Install Vagrant & try again. Exiting..."
    exit 1
  else
    print_line "Install: Already installed"
  fi
}

vagrant_get_plugins() {
  if $vagrant_plugins_install; then
    for plugin in $vagrant_plugins; do
      print_line "Plugins: Checking for: $plugin"
      if ! vagrant plugin list | grep -q -i $plugin ; then
        print_line "Plugins: Installing: $plugin"
        vagrant plugin install $plugin
      else
        print_line "Plugins: Already installed: $plugin"
      fi
    done
  fi
}

vagrant_download_boxes() {
  if [ ! -z $vagrant_boxstore_url ]; then
  for box in $boxes; do
    if [[ "$box" -ne 'default' ]]; then
    print_line "Boxes: Download box: '$box'"
    vagrant box add "${vagrant_boxstore_url}/${box}.box"
    fi
  done
  fi
}

vagrant_get_box_names() {
  boxes=$(vagrant status --machine-readable | grep metadata | awk -F',' '{print $2}' | awk '{printf("%s,",$0)}' | sed 's/,\s*$//')
  return $?
}

ansible_install() {
  installed=$(which ansible && echo $?)
  if [ "$installed" == '1' ]; then
    # print_line "Install: Installing ..."
    print_line "Install: Ansible NOT installed. Auto installation is not yet supported. Install Ansible & try again. Exiting..."
    exit 1
  else
    print_line "Install: Already installed"
  fi
}

ansible_config() {
  if $ansible_replace_config; then
    print_line "Config: Removing current ansible.cfg"
    rm -f ansible.cfg  
  fi
  
  if [ ! -e ansible.cfg ]; then
    print_line "Config: Downloading 'clean' ansible.cfg"
    curl -s https://raw.githubusercontent.com/ansible/ansible/devel/examples/ansible.cfg -o ansible.cfg
  fi

  print_line "Config: Setting 'roles_path' to: 'ansible/roles'"
  sed_replace 'ansible.cfg' '#roles_path' 'roles_path = ansible/roles'

  if [[ $ansible_use_log_plugin == true ]]; then
    print_line "Config: Setting 'callback_plugins' to: 'ansible/plugins'"
    sed_replace 'ansible.cfg' '#callback_plugins' 'callback_plugins = ansible/plugins'
  fi

  print_line "Config: Settings 'cows' to off"
  sed_replace 'ansible.cfg' '#nocows' 'nocows = 1'

  print_line "Config: Disable retry files"
  sed_replace 'ansible.cfg' '#retry_files_enabled' 'retry_files_enabled = false'
}

ansible_playbook_repo_clone() {
  ret=0
  if [ ! -z "$ansible_playbook_repo" ]; then
    # Check if dir exists already
    if [ -d ./ansible ]; then
      print_line "Repo: Already cloned, pulling latest changes"
      cd $ansible_playbook_repo
      git pull
      ret=$?
      cd ..
    else
      print_line "Repo: Cloning repo to ./ansible"
      git clone $ansible_playbook_repo ./ansible
      ret=$?
    fi
  fi
  return $?
}

ansible_plugins() {
  if $ansible_replace_config && $ansible_use_log_plugin; then
    if [ ! -e ansible/plugins/human_log.py ]; then
    print_line "Plugins: Downloading 'Human' Readable Ouptut"
    mkdir -p ansible/plugins
    # Source: https://gist.github.com/cliffano/9868180    
    # plugin_link="https://gist.githubusercontent.com/dmsimard/cd706de198c85a8255f6/raw/a2332f282be6e47286f588a9af6c10ff1b92749d/human_log.py"
    # plugin_link="https://raw.githubusercontent.com/redhat-openstack/khaleesi/master/plugins/callbacks/human_log.py"
    plugin_link="https://raw.githubusercontent.com/n0ts/ansible-human_log/master/human_log.py"
    curl -s $plugin_link -o ansible/plugins/human_log.py
    fi
  fi
}

ansible_prompt_vault_password() {
  if $ansible_ask_for_vault_password; then

    # Check if file already exists
    if [ -f ./ansible/vault-password.txt ]; then
      print_line "Vault Password: File already exists, skipping..."
    else
      print_line
      print_line "\tVault Password: Enter the vault password: "
      print_line 
      read -s ansible_vault_password
      echo $ansible_vault_password > ansible/vault-password.txt
      print_line "Vault Password: Saved to file: ansible/vault-password.txt"
    fi
  fi
}

ansible_get_requirements() {
  if [ -f ./ansible/requirements ]; then
    if [ ! -d .ansible/roles ]; then
      mkdir -p ansible/roles
    fi
  ansible-galaxy install -p ./ansible/roles/ -r ./ansible/requirements.yml
  fi
}

vm_check_status() {
  print_line "Boxes: Checking box: $1"
  is_running=$(vagrant status $1 --machine-readable | grep -m 1 'state' | awk -F',' '{print $4}')
  if [[ "$is_running" == 'running' ]]; then
    print_line "Boxes: Box is currently running: '$1'"
  else
    print_line "Boxes: Box is NOT running: '$1'"
  fi
  [[ "$is_running" == 'running' ]] && return 1 || return 0
}

vm_destroy() {
  print_line "Boxes: Destroying box: '$1'"
  vagrant destroy -f $1
  return $?
}

vm_start() {
  if $(in_list $1); then
    print_line "Boxes: Starting Box: '$1'"
    vagrant up --provider=$box_provider $1
  fi
  [[ $? == 0 ]] && return 0 || return 1
}
#####################################################
#	 	MAIN CODE                                   #
#####################################################
print_line "#####################################################"
print_line "#	 	Vagrant Automaton 9000                    #"
print_line "#####################################################\n"

print_line "#####################################################"
print_line "#	 	Variables                                 #"
print_line "#####################################################"
# for var in start dts boxes box_provider vagrant_plugins_install vagrant_plugins vagrant_force_provisioning vagrant_force_reload ansible_ask_vault_password ansible_replace_config ansible_use_log_plugin ansible_playbook_repo; do
#     printf "%-60s %-40s\n" "$print_prefix $var" ${!var}
# done
while read -r name value; do
  printf "%-65s %-40s\n" "$print_prefix $name" ${!name}
done < run.properties

print_done

exit 0

print_line "#####################################################"
print_line "#	 	Vagrant                                   #"
print_line "#####################################################"
vagrant_install
vagrant_get_plugins
# Handled by Vagrantfile
# vagrant_download_boxes
print_done

print_line "#####################################################"
print_line "#	 	Ansible                                   #"
print_line "#####################################################"
ansible_install
ansible_config
ansible_playbook_repo_clone
ansible_plugins
ansible_prompt_vault_password
# Handled by Vagrantfile
# ansible_get_requirements
print_done

print_line "#####################################################"
print_line "#	 	Boxes                                     #"
print_line "#####################################################"
print_line "Boxes: Box(es) is/are: $boxes"
for box in $boxes
do
	if !(vm_check_status $box); then
    vm_destroy $box
  fi

  if (vm_start $box); then
    print_line "Boxes: Box Started Successfully: '$box'"
  else
    print_line "Boxes: !!! ERROR !!!"
    print_line "Boxes: !!! ERROR !!!   Unable to bring up box: '$box'"
    print_line "Boxes: !!! ERROR !!!"
  fi

  if $vagrant_force_provisioning; then
    vagrant provision $box
  fi

  if $vagrant_force_reload; then
    vagrant reload $box
  fi
done
print_line "#####################################################"
end=`date +%s`
print_line "Total execution time: $((end-start)) seconds"
print_line "#####################################################"
print_line "#	 	Vagrant Automaton 9000                    #"
print_line "#####################################################"
exit 0
#####################################################
#	 	TODOs                                       #
#####################################################
# - Install Vagrant if not found
# - Install Ansible if not found
# - Install VirtualBox if not found
# - Check exit codes and stop script on error