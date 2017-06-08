# HPCW Vagrant Template

### Run.sh
run.sh is a wrapper script that helps easily setup a new project for use with Ansible and helps keep projects consistent.
The script is still a WIP but end goals are:
- Provides pretty output
    - Is property file driven for max configuration/compatability
    - Shows all used variables
    - Shows overall run time
- Checks for and auto updates itself
- Checks if Vagrant is installed
    - TODO: Installs Vagrant
    - Checks for and installs any required Vagrant plugins
- Checks if Ansible is installed
    - TODO: Installs Ansible
    - Configures Ansible's plugins/config file as needed
- Checks if the desired vagrant box is already running
    - If it is, it's destroyed
- Starts the Vagrant box
    - Which inherently starts the provisioner defined in the Vagrantfile

### run.properties
All "user variables" are defined in the run.properties file. The properties file is self documenting aswell.    
Variable Overview is as follows:

    # script_version=<some_version>
"# script_version" is used to determine if the repo has an update the script needs updated.

    script_check_updates=true
"script_check_updates" is a boolean to perform and update check and update the run.sh script

    script_src_repo=<repo_link>
"script_src_repo" links to this repo initially. If you fork, be sure to change this

    vagrant_boxes='default'
"vagrant_boxes" is a comma delimited list of vagrant box names. These names MUST corrilate with the names of the boxes defined in the Vagrantfile. If only a single box is defined, the value 'default' can be used.       
__Defaults to: 'default' (This is the default name of a vagrant box unless you specifically specify a name in the Vagrantfile)__

    vagrant_box_provider=virtualbox
"vagrant_box_provider" tells Vagrant which VM provider to use.  
__Defaults to: "virtualbox"__

    vagrant_plugins_install=true
"vagrant_plugins_install" is a boolean flag to determine if the script should install any additional Vagrant plugins your project might need. If you're using a RHEL box, keep this true  
__Defaults to: true__

    vagrant_plugins='vagrant-registration'
"vagrant_plugins" is a comma delimited list of Vagrant plugins needed for your project. If you're using a RHEL box, keep _vagrant-registration_  
__Defaults to: vagrant-registration__

    vagrant_force_provisioning=false
"vagrant_force_provisioning" is a boolean that force provisiong to be called after the vagrant box has started. Vagrant automatically provisions boxes upon first boot. This is NOT normally needed.  
__Defaults to: false__

    vagrant_force_reload_after_provision=false
"vagrant_force_reload_after_provision" is a boolean that will cause the box to be restarted after the provisioning is completed.  
__Defaults to: false__

    vagrant_boxstore_url=''
"vagrant_boxstore_url" is the link to use for your box repo. This should be the base url as the variable is used as: ${vagrant_boxstore_url}/${vagrant_box}.box
__Defaults to: *empty*__

    ansible_replace_config=true
"ansible_replace_config" allows you to skip using a custom ansible.cfg but will break any Ansible plugins and/or possible roles (although Ansible is smart enough to see a /roles dir from where it's ran)  
__Defaults to: true and you should keep it that way__

    ansible_use_log_plugin=true
"ansible_use_log_plugin" allows you to NOT use the **human readable printout plugin**  
__Defaults to: true__

    ansible_playbook_repo=''
"ansible_playbook_repo" is the link to the repo containing the playbook needed to configure the box. This repo is cloned to: "<project_root>/ansible" directory. The corresponding *:playbook* variable in the Vagrantfile should include any pathing beyond this directory.
__Defaults to: *empty*__

    ansible_ask_for_vault_password=false
"ansible_ask_for_vault_password" is a boolean to control if you want the script to save the vault password in a plain text file which can then be defined in the Vagrantfile so you are NOT prompted every box run for the password
__Defaults to: false__
