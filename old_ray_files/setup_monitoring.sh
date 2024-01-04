#!/bin/bash

# Navigate to /usr/src/app/ directory
cd /usr/src/app/

# Prometheus setup
echo "Setting up Prometheus..."
wget https://github.com/prometheus/prometheus/releases/download/v2.49.0-rc.1/prometheus-2.49.0-rc.1.linux-amd64.tar.gz
tar xvfz prometheus-*.tar.gz
rm prometheus-*.tar.gz
./replace_prometheus.sh
cd prometheus-*
nohup ./prometheus --config.file=/dev/shm/ray_tmp/ray/session_latest/metrics/prometheus/prometheus.yml &
cd /usr/src/app/

# Grafana setup
echo "Setting up Grafana..."
wget https://dl.grafana.com/enterprise/release/grafana-enterprise-10.2.3.linux-amd64.tar.gz
tar -zxvf grafana-enterprise-10.2.3.linux-amd64.tar.gz
rm grafana-*.tar.gz
./replace_grafana.sh
cd grafana-*
nohup ./bin/grafana-server --config /dev/shm/ray_tmp/ray/session_latest/metrics/grafana/grafana.ini web > grafana_output.log 2>&1 &
cd /usr/src/app/

echo "Monitoring tools setup completed."

