#!/usr/bin/env bash

# This is the parent script for all proxy scripts.
# Using this script should provision the server from
# start to finish.

# https://deviantengineer.com/2015/05/nginx-reverseproxy-centos7/

# walkthrough for installing Nginx, and configuring it as a reverse proxy.
# Should use a self-signed wild card SSL and access all services through this without putting those services directly on the internet
# Can use for Guacamole, SABnzbd/SickBeard/CouchPotatoServer/Headphones, SubSonic, Plex Media Server, and Owncloud.

# For clarity, I will be running Nginx as a user called nginx.
# SELinux will be disable, and firewalld will be configured to only allow inbound 22 and 443 traffic (only 443 will be available on the internet).

echo 'scripts ==> ssl ==> START'
# http://www.akadia.com/services/ssh_test_certificate.html
# http://www.jamescoyle.net/how-to/1073-bash-script-to-create-an-ssl-certificate-key-and-request-csr
rm -rf /app/ssl
mkdir -p /app/ssl
cd /app/ssl
# Generate a Private Key
echo 'Generating key for domain...'
openssl genrsa -des3 -passout pass:welcome1 -out server.key 2048 -noout
# Remove Passphrase from Key
echo 'Removing passphrase...'
openssl rsa -in server.key -passin pass:welcome1 -out server.key
# Generate a CSR (Certificate Signing Request)
echo 'Generating CSR (Certificate Signing Request)...'
openssl req -new -key server.key -out server.csr -passin pass:welcome1 -subj "/C=US/ST=IOWA/L=America/O=HillsPCWorld/OU=IT/CN=HPCW/emailAddress=Hill@HillsPCWorld.com"
# Generating a Self-Signed Certificate
echo 'Generating self signed cert...'
openssl x509 -req -days 365 -in server.csr -signkey server.key -passin pass:welcome1 -out server.crt
echo 'scripts ==> ssl ==> END'
echo ''


# Prerequisites
echo 'Prerequisites...'
# Disabled SELinux
sed -i /etc/selinux/config -r -e 's/^SELINUX=.*/SELINUX=disabled/g'
# Install EPEL repo
yum -y install epel-release
# Run all updates before starting, and apply new SELinux settings
yum -y update
# yum -y update && systemctl reboot   # Run all updates before starting, and apply new SELinux settings

# nginx has some dependencies that are only available in the cr which requires yum-utils -.-
yum -y install yum-utils
yum-config-manager --enable cr


# nginx install & setup
echo 'nginx setup...'
# Install nginx
yum -y install nginx
useradd -r nginx -p welcome1
# Create backup of nginx.conf
mv /etc/nginx/nginx.conf /etc/nginx/nginx.conf.orig

cat >/etc/nginx/nginx.conf <<EOL
user  nginx;
worker_processes  2;   # Set to number of CPU cores
error_log  /var/log/nginx/error.log;
pid  /run/nginx.pid;

events {
    worker_connections  1024;
}

http {
  include  /etc/nginx/mime.types;
  default_type  application/octet-stream;

  log_format  main '$remote_addr - $remote_user [$time_local] "$request" '
              '$status $body_bytes_sent "$http_referer" '
              '"$http_user_agent" "$http_x_forwarded_for"';

  access_log  /var/log/nginx/access.log  main;

  sendfile  on;

  keepalive_timeout  65;

  include /etc/nginx/conf.d/*.conf;

  index  index.html index.htm;
}
EOL

# nginx proxy config
echo 'nginx config...'
cat >/etc/nginx/conf.d/reverseproxy.conf <<EOL
ssl_certificate  /app/ssl/server.crt;   # Replace with your cert info (I generate my own self-signed certs with openssl)
ssl_certificate_key  /app/ssl/server.key;   # Replace with your cert info (I generate my own self-signed certs with openssl)
ssl_session_timeout  5m;
ssl_prefer_server_ciphers  on;
ssl_protocols  TLSv1 TLSv1.1 TLSv1.2;
ssl_ciphers  AES256+EECDH:AES256+EDH:!aNULL;

server  {

  listen  80;   # Redirect any port http/80 requests, to https/443 -- generally only matters for internal requests
  server_name  *.domain.com;
  return 301 https://$host$request_uri;
}

server  {
  listen  443 ssl;   # Return 404 page if requesting the root url; can set this to whatever you want, but I just leave this at a 404
  server_name domain.com;
  ssl  on;
  location  / {
    return  404;
  }
}

server  {
  listen  443 ssl;   # Example config for SubSonic, browsable at https://subsonic.domain.com
  server_name  subsonic.domain.com;
  ssl  on;
  location  / {
    proxy_pass  http://interal_ip_to_subsonic:4040/;
  }
}

server  {
  listen  443 ssl;   # Example config for OwnCloud, browsable at https://owncloud.domain.com
  server_name  owncloud.domain.com;
  client_max_body_size  0;
  ssl  on;
  location  / {
    proxy_pass  http://internal_ip_to_owncloud/;
  }
}

server  {
  listen  443 ssl;   # Example config for SABnzbd, browsable at https://sab.domain.com
  server_name  sab.proxy.dev.hpcw.com;
  ssl  on;
  location  / {
    proxy_pass  http://10.0.0.157:9090/;
  }
}

server  {
  listen  443 ssl;   # Example config for SickRage, browsable at https://sr.domain.com
  server_name  sr.domain.com;
  ssl  on;
  location  / {
    proxy_pass  http://interal_ip_to_sickrage:8081/;
  }
}

server  {
  listen  443 ssl;   # Example config for CouchPotatoServer, browsable https://cps.domain.com
  server_name  cps.domain.com;
  ssl  on;
  location  / {
    proxy_pass  http://internal_ip_to_sickbeard:5050/;
  }
}

server  {
  listen  443 ssl;   # Example config for Headphones, browsable at https://hp.domain.com
  server_name  hp.domain.com;
  ssl  on;
  location  / {
    proxy_pass  http://internal_ip_to_headphones:9090/;
  }
}

server  {
  listen  443 ssl;   # Example config for Guacamole, browsable at https://guac.domain.com/guacamole
  server_name  guac.domain.com;
  ssl  on;
  location  / {
    proxy_buffering  off;
    proxy_pass  http://interl_ip_to_guacamole:8080/;
  }
}

server  {
  listen  443 ssl;   # Example config for Plex Media Server, browsable at https://pms.domain.com/web
  server_name  pms.domain.com;
  ssl  on;
  location  / {
    proxy_pass  http://internal_ip_to_plex:32400/;
  }
}

server {
  listen  443 ssl;    # Example config for Stash, browsable at https://git.domain.com
  server_name  git.domain.com;
  ssl  on;
  client_max_body_size  256m;
  location  / {
    proxy_pass  http://internal_ip_to_stash:7990;
    proxy_set_header  X-Forwarded-Host $host;
    proxy_set_header  X-Forwarded-Server $host;
    proxy_set_header  X-Forwarded-For $proxy_add_x_forwarded_for;
  }
}
EOL

# Start nginx as system boot
systemctl enable nginx.service

# Configure Firewall
echo 'Firewall config...'
# Start firewalld
systemctl enable firewalld.service
systemctl start firewalld
firewall-cmd --permanent --add-service=http
firewall-cmd --permanent --add-service=https

# Reboot
echo 'Rebooting...'
systemctl reboot

# Don't forget to forward port 443 on your firewall,
# and set up dns entries with your dns provider
# (pro-tip: Set up a wild card A Record such as *.domain.com and point that to your IP)
