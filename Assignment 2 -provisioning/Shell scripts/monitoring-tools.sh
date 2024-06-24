#!/bin/bash


sudo apt-get update
sudo apt-get install -y wget tar


PROMETHEUS_VERSION="2.27.1"
wget https://github.com/prometheus/prometheus/releases/download/v${PROMETHEUS_VERSION}/prometheus-${PROMETHEUS_VERSION}.linux-amd64.tar.gz
tar xvf prometheus-${PROMETHEUS_VERSION}.linux-amd64.tar.gz
sudo mv prometheus-${PROMETHEUS_VERSION}.linux-amd64 /usr/local/prometheus


sudo useradd --no-create-home --shell /bin/false prometheus
sudo mkdir -p /etc/prometheus
sudo mkdir -p /var/lib/prometheus


sudo mv /usr/local/prometheus/prometheus.yml /etc/prometheus/
sudo mv /usr/local/prometheus/consoles /etc/prometheus/
sudo mv /usr/local/prometheus/console_libraries /etc/prometheus/


sudo chown -R prometheus:prometheus /etc/prometheus
sudo chown -R prometheus:prometheus /var/lib/prometheus
sudo chown prometheus:prometheus /usr/local/prometheus/prometheus
sudo chown prometheus:prometheus /usr/local/prometheus/promtool


sudo tee /etc/systemd/system/prometheus.service >/dev/null <<EOF
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/prometheus/prometheus \\
  --config.file=/etc/prometheus/prometheus.yml \\
  --storage.tsdb.path=/var/lib/prometheus/ \\
  --web.console.templates=/etc/prometheus/consoles \\
  --web.console.libraries=/etc/prometheus/console_libraries

[Install]
WantedBy=multi-user.target
EOF


sudo systemctl daemon-reload
sudo systemctl start prometheus
sudo systemctl enable prometheus


wget https://dl.grafana.com/oss/release/grafana_8.0.6_amd64.deb
sudo dpkg -i grafana_8.0.6_amd64.deb


sudo systemctl start grafana-server
sudo systemctl enable grafana-server


echo "Prometheus and Grafana installation completed."
sudo systemctl status prometheus
sudo systemctl status grafana-server
