#!/usr/bin/env bash

# Update
sudo yum update -y

# With SELinux enabled, this is required...
sudo yum install -y libselinux-python