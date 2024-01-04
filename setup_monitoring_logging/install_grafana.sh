#!/bin/bash

# https://grafana.com/docs/grafana/latest/setup-grafana/installation/redhat-rhel-fedora/

# install Grafana from the RPM repository
wget -q -O gpg.key https://rpm.grafana.com/gpg.key
sudo rpm --import gpg.key
rm -f gpg.key

# create a grafana.repo file
sudo bash -c 'cat > /etc/yum.repos.d/grafana.repo' << EOF
[grafana]
name=grafana
baseurl=https://rpm.grafana.com
repo_gpgcheck=1
enabled=1
gpgcheck=1
gpgkey=https://rpm.grafana.com/gpg.key
sslverify=1
sslcacert=/etc/pki/tls/certs/ca-bundle.crt
exclude=*beta*
EOF

# install Grafana
sudo dnf install grafana -y

# enable and start Grafana service
sudo systemctl enable grafana-server
sudo systemctl start grafana-server

