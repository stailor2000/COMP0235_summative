#!/bin/bash

# based on https://devopscube.com/install-configure-prometheus-linux/#:~:text=Step%201%3A%20Update%20the%20yum%20package%20repositories.&text=Step%202%3A%20Go%20to%20the,extracted%20folder%20to%20prometheus%2Dfiles.

# 'download the source using curl, untar it, and rename the extracted folder to prometheus-files.'
curl -LO https://github.com/prometheus/prometheus/releases/download/v2.49.0-rc.1/prometheus-2.49.0-rc.1.linux-amd64.tar.gz
tar xvf prometheus-2.49.0-rc.1.linux-amd64.tar.gz
mv prometheus-2.49.0-rc.1.linux-amd64 prometheus-files
rm prometheus-2.49.0-rc.1.linux-amd64.tar.gz

# 'create a Prometheus user, required directories, and make Prometheus the user 
# as the owner of those directories.'
sudo useradd --no-create-home --shell /bin/false prometheus
sudo mkdir /etc/prometheus
sudo mkdir /var/lib/prometheus
sudo chown prometheus:prometheus /etc/prometheus
sudo chown prometheus:prometheus /var/lib/prometheus

# 'copy prometheus and promtool binary from prometheus-files folder to 
# /usr/local/bin and change the ownership to prometheus user.'
sudo cp prometheus-files/prometheus /usr/local/bin/
sudo cp prometheus-files/promtool /usr/local/bin/
sudo chown prometheus:prometheus /usr/local/bin/prometheus
sudo chown prometheus:prometheus /usr/local/bin/promtool

# 'move the consoles and console_libraries directories from prometheus-files to 
# /etc/prometheus folder and change the ownership to prometheus user.''
sudo cp -r prometheus-files/consoles /etc/prometheus
sudo cp -r prometheus-files/console_libraries /etc/prometheus
sudo chown -R prometheus:prometheus /etc/prometheus/consoles
sudo chown -R prometheus:prometheus /etc/prometheus/console_libraries

# setup Prometheus Configuration
sudo cp prometheus.yml /etc/prometheus/prometheus.yml
sudo chown prometheus:prometheus /etc/prometheus/prometheus.yml

# setup Prometheus Service File
sudo bash -c 'cat > /etc/systemd/system/prometheus.service' << EOF
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/prometheus \
    --config.file /etc/prometheus/prometheus.yml \
    --storage.tsdb.path /var/lib/prometheus/ \
    --web.console.templates=/etc/prometheus/consoles \
    --web.console.libraries=/etc/prometheus/console_libraries

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd to apply new service
sudo systemctl daemon-reload
sudo systemctl start prometheus

