#!/bin/bash

# based on: https://devopscube.com/monitor-linux-servers-prometheus-node-exporter/

# Ssetup Node Exporter Binary
wget https://github.com/prometheus/node_exporter/releases/download/v1.7.0/node_exporter-1.7.0.linux-amd64.tar.gz
tar xvfz node_exporter-1.7.0.linux-amd64.tar.gz
rm node_exporter-1.7.0.linux-amd64.tar.gz
sudo mv node_exporter-1.7.0.linux-amd64/node_exporter /usr/local/bin/
rm -rd node_exporter-1.7.0.linux-amd64/
sudo useradd -rs /bin/false node_exporter

# create a Custom Node Exporter Service
sudo bash -c 'cat > /etc/systemd/system/node_exporter.service' << EOF
[Unit]
Description=Node Exporter
After=network.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=multi-user.target
EOF

# reload systemd to apply the new service
sudo systemctl daemon-reload
sudo systemctl start node_exporter
sudo systemctl enable node_exporter

